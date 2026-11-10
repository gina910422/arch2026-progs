# op1, op2, op3 and q_mul: hand-written RV32I.
#
# uint32_t op1_asm(uint32_t a, uint32_t b, int *n)   a0, a1, a2 -> a0
# uint32_t op2_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# uint32_t op3_asm(uint32_t a, uint32_t b)           a0, a1 -> a0
# int32_t  q_mul_asm(int32_t a, int32_t b)           a0, a1 -> a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. q_mul forms a 64-bit product in a register pair. Tests:
# tests/tfixed.c.

    .text

    .globl  op1_asm
    .type   op1_asm, @function
    .align  2
op1_asm:
    li      t0, 0
op1_loop:    
    beq     a1, x0, op1_result    # a1 is zero: the answer is in a0
    and     t1, a0, a1            # t1 = (a & b)
    xor     a0, a0, a1            # a = a ^ b
    slli    a1, t1, 1             # b = t1 << 1
    
    addi    t0, t0, 1
    j       op1_loop
op1_result:
    sw      t0, 0(a2)             
    ret
    .size   op1_asm, .-op1_asm

    .globl  op2_asm
    .type   op2_asm, @function
    .align  2
op2_asm:
    sub     a0, a0, a1
    ret
    .size   op2_asm, .-op2_asm

    .globl  op3_asm
    .type   op3_asm, @function
    .align  2
op3_asm:
    srli    t0, a0, 1             # a >> 1
    srli    t1, a1, 1             # b >> 1
    and     t2, a0, a1            # a & b & 1
    andi    t2, t2, 1

    add     a0, t0, t1            # (a >> 1) + (b >> 1) + (a & b & 1)
    add     a0, a0, t2
    ret
    .size   op3_asm, .-op3_asm

    .globl  q_mul_asm
    .type   q_mul_asm, @function
    .align  2
q_mul_asm:
    xor     t2, a0, a1            # a, b 是否異號

    bge     a0, zero, q_mul_a_positive
    sub     a0, zero, a0          # a: Two's Complement
q_mul_a_positive:
    bge     a1, zero, q_mul_b_positive
    sub     a1, zero, a1          # b: Two's Complement
q_mul_b_positive:  
    li      a2, 0                 # a2 = result_low
    li      a3, 0                 # a3 = result_high
    li      t0, 0                 # t0 = a_high
q_mul_loop:
    beq     a1, zero, q_mul_sign
    andi    t1, a1, 1
    beq     t1, zero, q_mul_next  # b & 1
    
    # result
    add     a2, a0, a2            # a2 = result_low = result_low + a_low
    # (a_low + result_low) overflow? 
    sltu    t1, a2, a0            # t1 = carry = (t1 < a0) ? 1 : 0;
    add     a3, a3, t0            # result_high = result_high + a_high
    add     a3, a3, t1            # result_high = result_high + carry
q_mul_next:
    # a << 1
    slli    t0, t0, 1             # a_high << 1
    srli    t1, a0, 31            # a_low[31]
    add     t0, t0, t1            # a_high + a_low[31]
    slli    a0, a0, 1             # a_low << 1
    # b >> 1
    srli    a1, a1, 1             
    j       q_mul_loop
q_mul_sign:
    bge     t2, zero, q_mul_result

    # 64-bit Two's Complement
    not     a2, a2
    not     a3, a3

    addi    a2, a2, 1
    sltiu   t0, a2, 1             # t0 = carry = ((result_low + 1) < 1) ? 1 : 0;
    add     a3, a3, t0
q_mul_result:
    # result
    li      t0, 0x00080000
    add     a2, a2, t0            # a2 = result_low = result_low + (1 << 19)
    # a * b + (1 << (Q - 1)) overflow? 
    sltu    t1, a2, t0            # t1 = carry = (a2 < t0) ? 1 : 0
    add     a3, a3, t1            # result_high = result_high + carry
    
    srli    t1, a2, 20            # result_low[31:20] -> resllt[11:0]
    slli    t2, a3, 12            # result_high[19:0] -> resllt[31:12]
    or      a0, t1, t2
    ret
    
    .size   q_mul_asm, .-q_mul_asm
