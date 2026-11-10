# gcd_u32_asm: binary GCD, hand-written RV32I.
#
# uint32_t gcd_u32_asm(uint32_t a, uint32_t b)   a in a0, b in a1, result in a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions. Tests: tests/tgcd.c.

    .text

    .globl  gcd_u32_asm
    .type   gcd_u32_asm, @function
    .align  2
gcd_u32_asm:
    beq     a0, x0, gcd_u32_alt   # a0 is zero: the answer is in a1
    beq     a1, x0, gcd_u32_end   # a1 is zero: a0 already holds it
    addi    t0, x0, 0             # count of shared twos, starting here
gcd_u32_both:
    or      t1, a0, a1            # combine a and b
    andi    t1, t1, 1             # keep the parity bit
    bne     t1, x0, gcd_u32_left
    srli    a0, a0, 1             # a /= 2, with no sign to preserve
    srli    a1, a1, 1             # b /= 2
    addi    t0, t0, 1             # one more shared two
    j       gcd_u32_both          # back to the head of this loop
gcd_u32_left:
    andi    t1, a0, 1
    bne     t1, x0, gcd_u32_right # a is odd now, go work on b
gcd_u32_left_shift:  
    srli    a0, a0, 1
    andi    t1, a0, 1
    beq     t1, x0, gcd_u32_left_shift
    j       gcd_u32_order
gcd_u32_right:
    andi    t1, a1, 1
    bne     t1, x0, gcd_u32_order
gcd_u32_right_shift:
    srli    a1, a1, 1
    andi    t1, a1, 1
    beq     t1, x0, gcd_u32_right_shift
gcd_u32_order:
    bgeu    a1, a0, gcd_u32_step  # while b >= a: swap 
    mv      t1, a0
    mv      a0, a1
    mv      a1, t1
gcd_u32_step:
    sub     a1, a1, a0            # b -= a, and b stays even
    beq     a1, x0, gcd_u32_shift # b is not zero yet
    j       gcd_u32_right_shift
gcd_u32_shift:
    sll     a0, a0, t0            # put the shared twos back
    ret
gcd_u32_alt:
    addi    a0, a1, 0
gcd_u32_end:
    ret

    .size   gcd_u32_asm, .-gcd_u32_asm
