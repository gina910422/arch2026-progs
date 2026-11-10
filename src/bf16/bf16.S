# BFloat16 routines: hand-written RV32I.
#
# uint16_t bf16_from_f32_asm(uint32_t f32bits)   a0 -> a0
# uint16_t bf16_mul_asm(uint16_t a, uint16_t b)  a0, a1 -> a0
# uint16_t bf16_sqrt_asm(uint16_t a)             a0 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tbf16.c.

    .text

    .globl  bf16_from_f32_asm
    .type   bf16_from_f32_asm, @function
    .align  2
bf16_from_f32_asm:
    srli    t0, a0, 23           # exp 移到最低位
    andi    t0, t0, 0xFF

    li      t1, 0xFF
    beq     t0, t1, bf16_from_f32_finish
    
    li      t1, 0x7FFF
    add     t2, a0, t1           # t2 = f32bits + 0x7FFF
    srli    t3, a0, 16
    andi    t3, t3, 1            # t3 = (f32bits >> 16) & 1
    add     a0, t2, t3           # a0 = t2 + t3
bf16_from_f32_finish:
    srli    a0, a0, 16           # a0 = f32bits >> 16
    ret
    .size   bf16_from_f32_asm, .-bf16_from_f32_asm

    .globl  bf16_mul_asm
    .type   bf16_mul_asm, @function
    .align  2
bf16_mul_asm:
    # a
    srli    t0, a0, 15
    andi    t0, t0, 1            # t0 = sign_a
    srli    t1, a0, 7
    andi    t1, t1, 0xFF         # t1 = exp_a
    andi    t2, a0, 0x7F         # t2 = mant_a
    # b
    srli    t3, a1, 15
    andi    t3, t3, 1            # t3 = sign_b
    srli    t4, a1, 7
    andi    t4, t4, 0xFF         # t4 = exp_b
    andi    t5, a1, 0x7F         # t5 = mant_b

    xor     a2, t0, t3           # result sign
    # special cases
    # a: NaN / Inf
    li      t6, 0xFF
    beq     t1, t6, special_cases_a
    # b: NaN / Inf
    beq     t4, t6, special_cases_b
    # a or b: zero
    or      t6, t1, t2          #  exp_a || mant_a
    beq     t6, zero, special_cases_Zero
    or      t6, t4, t5          #  exp_b || mant_b
    beq     t6, zero, special_cases_Zero

    # normal / subnormal
    mv      a3, zero
    bne     t1, zero, a_normal
a_subnormal_loop:
    andi    t6, t2, 0x80
    bne     t6, zero, a_subnormal
    slli    t2, t2, 1
    addi    a3, a3, -1
    j       a_subnormal_loop
a_subnormal:
    li      t1, 1
    j       check_b
a_normal:
    ori     t2, t2, 0x80

check_b:
    bne     t4, zero, b_normal
b_subnormal_loop:
    andi    t6, t5, 0x80
    bne     t6, zero, b_subnormal
    slli    t5, t5, 1
    addi    a3, a3, -1
    j       b_subnormal_loop
b_subnormal:
    li      t4, 1
    j       bf16_mul_start
b_normal:
    ori     t5, t5, 0x80

bf16_mul_start:
    # mul     a4, t2, t5          # a4 = result_mant
    li      a4, 0
bf16_mul_loop:
    beq     t5, zero, bf16_mul_result
    andi    t6, t5, 1
    beq     t6, zero, bf16_mul_next
    add     a4, a4, t2
bf16_mul_next:    
    slli    t2, t2, 1
    srli    t5, t5, 1
    j       bf16_mul_loop
bf16_mul_result:
    add     a5, t1, t4
    addi    a5, a5, -127
    add     a5, a5, a3          # a5 = result_exp

# normalize
    li      t6, 0x8000
    and     t6, a4, t6
    beq     t6, zero, bf16_mul_normal
    srli    a4, a4, 8
    andi    a4, a4, 0x7F
    addi    a5, a5, 1
    j       bf16_mul_overflow
bf16_mul_normal:
    srli    a4, a4, 7
    andi    a4, a4, 0x7F
    
# overflow / underflow
bf16_mul_overflow:
    li      t6, 0xFF
    bge     a5, t6, special_cases_Inf

    blt     zero, a5, bf16_mul_finish

    li      t6, -6
    blt     a5, t6, special_cases_Zero

    li      t6, 1
    sub     t6, t6, a5
    srl     a4, a4, t6
    mv      a5, zero
bf16_mul_finish:
    slli    a2, a2, 15

    andi    a5, a5, 0xFF
    slli    a5, a5, 7

    andi    a4, a4, 0x7F

    or      a0, a2, a5
    or      a0, a0, a4
    ret

# NaN / Inf
special_cases_a:
    # a: NaN? 
    bne     t2, zero, special_cases_a_NaN
    # b: zero?
    or      t6, t4, t5          # exp_b || mant_b
    beq     t6, zero, special_cases_NaN
    j       special_cases_Inf
special_cases_a_NaN: 
    ret

special_cases_b:
    # b: NaN? 
    bne     t5, zero, special_cases_b_NaN
    # a: zero?
    or      t6, t1, t2          # exp_a || mant_a
    beq     t6, zero, special_cases_NaN
    j       special_cases_Inf
special_cases_b_NaN:
    mv      a0, a1
    ret

special_cases_NaN:
    li      a0, 0x7FC0
    ret
special_cases_Inf:
    slli    a0, a2, 15
    li      t6, 0x7F80
    or      a0, a0, t6
    ret
special_cases_Zero:
    slli    a0, a2, 15
    ret
    .size   bf16_mul_asm, .-bf16_mul_asm

    .globl  bf16_sqrt_asm
    .type   bf16_sqrt_asm, @function
    .align  2
bf16_sqrt_asm:
    srli    t0, a0, 15
    andi    t0, t0, 1            # t0 = sign
    srli    t1, a0, 7
    andi    t1, t1, 0xFF         # t1 = exp
    andi    t2, a0, 0x7F         # t2 = mant

    # special cases
    # NaN / Inf
    li      t3, 0xFF
    beq     t1, t3, bf16_sqrt_special_cases
    # zero
    or      t3, t1, t2
    beq     t3, zero, bf16_sqrt_zero
    # negative
    bne     t0, zero, bf16_sqrt_special_cases_NaN
    #  positive subnormal
    beq     t1, zero, bf16_sqrt_zero
    j       bf16_sqrt_normal

bf16_sqrt_special_cases:
    bne     t2, zero, bf16_sqrt_special_cases_a_NaN
    bne     t0, zero, bf16_sqrt_special_cases_NaN
    li      a0, 0x7F80
    ret
bf16_sqrt_special_cases_a_NaN:
    ret
bf16_sqrt_special_cases_NaN:
    li      a0, 0x7FC0
    ret
bf16_sqrt_zero:
    li      a0, 0
    ret
    
# normal
bf16_sqrt_normal: 
# mant
    ori     t2, t2, 0x80
    addi    t1, t1, -127
# exponent
    andi    t3, t1, 1
    beq     t3, zero, bf16_sqrt_even
    slli    t2, t2, 1            # m <<= 1
    addi    a1, t1, -1
    srai    a1, a1, 1
    addi    a1, a1, 127          # a1 = result_exp = ((e - 1) >> 1) + BF16_EXP_BIAS
    j       bf16_sqrt_binary_search
bf16_sqrt_even:
    srai    a1, t1, 1
    addi    a1, a1, 127

# binary search
bf16_sqrt_binary_search:
    li      t3, 90               # t3 = low
    li      t4, 256              # t4 = high
    li      a2, 128
bf16_sqrt_binary_search_loop:
    blt     t4, t3, bf16_sqrt_finish
    add     t5, t3, t4
    srli    t5, t5, 1            # t5 = mid

    # mul     t6, t5, t5  
    mv      a3, t5
    mv      a4, t5
    li      t6, 0
bf16_sqrt_mul_loop:
    beq     a4, zero, bf16_sqrt_mul_result
    andi    a5, a4, 1
    beq     a5, zero, bf16_sqrt_mul_next
    add     t6, t6, a3
bf16_sqrt_mul_next:    
    slli    a3, a3, 1
    srli    a4, a4, 1
    j       bf16_sqrt_mul_loop
bf16_sqrt_mul_result:
    srli    t6, t6, 7           # t6 = sq = (mid * mid) / 128

    bltu    t2, t6, bf16_sqrt_sq
    mv      a2, t5
    addi    t3, t5, 1
    j       bf16_sqrt_binary_search_loop
bf16_sqrt_sq:
    addi    t4, t5, -1
    j       bf16_sqrt_binary_search_loop

bf16_sqrt_finish:
    andi    a1, a1, 0xFF
    slli    a1, a1, 7
    andi    a2, a2, 0x7F
    or      a0, a1, a2
    ret
    .size   bf16_sqrt_asm, .-bf16_sqrt_asm
