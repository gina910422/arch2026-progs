# rubik_solve_asm: optimal 2x2x2 cube solver, hand-written RV32I.
#
# int rubik_solve_asm(const char *state, char *out, size_t cap)
#                                   a0 = state, a1 = out, a2 = cap; result in a0
#
# RV32I and Zicsr only: no mul, div, rem, no floating point, no compressed
# instructions, no heap, no recursion. Tests: tests/trubik.c.

    .data

move_chars:
    .ascii "RRRBBBDDD"
move_suffix:
    .byte 0, '2', 39
    .byte 0, '2', 39
    .byte 0, '2', 39
move_face:
    .byte 0,0,0,1,1,1,2,2,2
state:
    .zero 14
path:
    .zero 12
solution_depth:
    .byte 0

    .text

    .globl rank_permutation
rank_permutation:
    # load all
    lbu     t0, 0(a0)
    lbu     t1, 1(a0)
    lbu     t2, 2(a0)
    lbu     t3, 3(a0)
    lbu     t4, 4(a0)
    lbu     t5, 5(a0)
    lbu     t6, 6(a0)

    li      a0, 0           # p = 0
    li      a1, 0           # smaller = 0

    # i = 0
    # j = 1
    bgeu    t1, t0, skip1   # if p[j] >= p[i], skip
    addi    a0, a0, 1
skip1: 
    # j = 2
    bgeu    t2, t0, skip2   # if p[j] >= p[i], skip
    addi    a0, a0, 1
skip2: 
    # j = 3
    bgeu    t3, t0, skip3   # if p[j] >= p[i], skip
    addi    a0, a0, 1
skip3: 
    # j = 4
    bgeu    t4, t0, skip4
    addi    a0, a0, 1
skip4: 
    # j = 5
    bgeu    t5, t0, skip5
    addi    a0, a0, 1
skip5: 
    # j = 6
    bgeu    t6, t0, skip6
    addi    a0, a0, 1

skip6:
    # i = 1
    # j = 2
    bgeu    t2, t1, skip7
    addi    a1, a1, 1
skip7: 
    # j = 3
    bgeu    t3, t1, skip8
    addi    a1, a1, 1
skip8: 
    # j = 4
    bgeu    t4, t1, skip9
    addi    a1, a1, 1
skip9: 
    # j = 5
    bgeu    t5, t1, skip10
    addi    a1, a1, 1
skip10: 
    # j = 6
    bgeu    t6, t1, skip11
    addi    a1, a1, 1
skip11: 
    slli    a2, a0, 1
    add     a1, a2, a1
    slli    a0, a0, 2
    add     a0, a0, a1

    # i = 2
    li      a1, 0
    # j = 3
    bgeu    t3, t2, skip12
    addi    a1, a1, 1
skip12:
    # j = 4
    bgeu    t4, t2, skip13
    addi    a1, a1, 1
skip13: 
    # j = 5
    bgeu    t5, t2, skip14
    addi    a1, a1, 1
skip14: 
    # j = 6
    bgeu    t6, t2, skip15
    addi    a1, a1, 1
skip15:
    add     a1, a0, a1
    slli    a0, a0, 2
    add     a0, a0, a1

    # i = 3
    li      a1, 0
    # j = 4
    bgeu    t4, t3, skip16
    addi    a1, a1, 1
skip16: 
    # j = 5
    bgeu    t5, t3, skip17
    addi    a1, a1, 1
skip17: 
    # j = 6
    bgeu    t6, t3, skip18
    addi    a1, a1, 1
skip18:
    slli    a0, a0, 2
    add     a0, a0, a1

    # i = 4
    li      a1, 0
    # j = 5
    bgeu    t5, t4, skip19
    addi    a1, a1, 1
skip19: 
    # j = 6
    bgeu    t6, t4, skip20
    addi    a1, a1, 1
skip20:
    add     a1, a0, a1
    slli    a0, a0, 1
    add     a0, a0, a1

    # i = 5
    li      a1, 0
    # j = 6 
    bgeu    t6, t5, skip21
    addi    a1, a1, 1
skip21:
    slli    a0, a0, 1       # p << 1
    add     a0, a0, a1      # (p << 1) + smaller

    ret

    .globl rank_orientation
rank_orientation:
    # li      t0, 0           # o = 0

    # lbu     t1, 7(a0)       # t1 = state->o[0]
    # add     t0, t0, t1      # t0 = (o << 1) + o + o[0]
    lbu     t0, 7(a0)       # o = state->o[0]

    lbu     t1, 8(a0)       # t1 = state->o[1]
    slli    t2, t0, 1       # t2 = o << 1
    add     t0, t2, t0      # t0 = (o << 1) + o
    add     t0, t0, t1      # t0 = (o << 1) + o + o[1]

    lbu     t1, 9(a0)       # state->o[2]
    slli    t2, t0, 1       # t2 = o << 1
    add     t0, t2, t0      # t0 = (o << 1) + o
    add     t0, t0, t1      # t0 = (o << 1) + o + o[2]

    lbu     t1, 10(a0)      # state->o[3]
    slli    t2, t0, 1       # t2 = o << 1
    add     t0, t2, t0      # t0 = (o << 1) + o
    add     t0, t0, t1      # t0 = (o << 1) + o + o[3]

    lbu     t1, 11(a0)      # state->o[4]
    slli    t2, t0, 1       # t2 = o << 1
    add     t0, t2, t0      # t0 = (o << 1) + o
    add     t0, t0, t1      # t0 = (o << 1) + o + o[4]
    
    lbu     t1, 12(a0)      # state->o[5]
    slli    t2, t0, 1       # t2 = o << 1
    add     t0, t2, t0      # t0 = (o << 1) + o
    add     a0, t0, t1      # a0 = (o << 1) + o + o[5]

    ret

    .globl valid
valid:
    li      t0, 0           # sum = 0
    li      t1, 7           # t1 = 7
    li      t2, 3           # t2 = 3

    # i = 0
    lbu     t3, 0(a0)       # load state->p[0]
    lbu     t4, 7(a0)       # load state->o[0]
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid

    add     t0, t0, t4

    # i = 1
    lbu t3, 1(a0)           # load state->p[1]
    lbu t4, 8(a0)           # load state->o[1]
    bgeu t3, t1, invalid
    bgeu t4, t2, invalid
    # j = 0
    lbu t5, 0(a0)           # load state->p[0]
    beq t3, t5, invalid

    add t0, t0, t4

    # i = 2
    lbu     t3, 2(a0)
    lbu     t4, 9(a0)
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid
    # j = 0
    lbu     t5, 0(a0)
    beq     t3, t5, invalid
    # j = 1
    lbu     t5, 1(a0)
    beq     t3, t5, invalid

    add     t0, t0, t4

    # i = 3
    lbu     t3, 3(a0)
    lbu     t4, 10(a0)
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid
    # j = 0
    lbu     t5, 0(a0)
    beq     t3, t5, invalid
    # j = 1
    lbu     t5, 1(a0)
    beq     t3, t5, invalid
    # j = 2
    lbu     t5, 2(a0)
    beq     t3, t5, invalid

    add     t0, t0, t4

    # i = 4
    lbu     t3, 4(a0)
    lbu     t4, 11(a0)
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid
    # j = 0
    lbu     t5, 0(a0)
    beq     t3, t5, invalid
    # j = 1
    lbu     t5, 1(a0)
    beq     t3, t5, invalid
    # j = 2
    lbu     t5, 2(a0)
    beq     t3, t5, invalid
    # j = 3
    lbu     t5, 3(a0)
    beq     t3, t5, invalid

    add     t0, t0, t4

    # i = 5
    lbu     t3, 5(a0)
    lbu     t4, 12(a0)
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid
    # j = 0
    lbu     t5, 0(a0)
    beq     t3, t5, invalid
    # j = 1
    lbu     t5, 1(a0)
    beq     t3, t5, invalid
    # j = 2
    lbu     t5, 2(a0)
    beq     t3, t5, invalid
    # j = 3
    lbu     t5, 3(a0)
    beq     t3, t5, invalid
    # j = 4
    lbu     t5, 4(a0)
    beq     t3, t5, invalid

    add     t0, t0, t4

    # i = 6
    lbu     t3, 6(a0)
    lbu     t4, 13(a0)
    bgeu    t3, t1, invalid
    bgeu    t4, t2, invalid
    # j = 0
    lbu     t5, 0(a0)
    beq     t3, t5, invalid
    # j = 1
    lbu     t5, 1(a0)
    beq     t3, t5, invalid
    # j = 2
    lbu     t5, 2(a0)
    beq     t3, t5, invalid
    # j = 3
    lbu     t5, 3(a0)
    beq     t3, t5, invalid
    # j = 4
    lbu     t5, 4(a0)
    beq     t3, t5, invalid
    # j = 5
    lbu     t5, 5(a0)
    beq     t3, t5, invalid

    add     t0, t0, t4

    li      t1, 0
    beq     t0, t1, valid_return
    li      t1, 3
    beq     t0, t1, valid_return
    li      t1, 6
    beq     t0, t1, valid_return
    li      t1, 9
    beq     t0, t1, valid_return
    li      t1, 12
    beq     t0, t1, valid_return
invalid:
    li      a0, 0
    ret
valid_return:
    li      a0, 1
    ret


    .globl parse_state
parse_state:
    li      t0, 49          # '1'
    li      t1, 55          # '7'
    li      t2, 51          # '3'
    # i = 0
    lbu     t3, 0(a0)       # load  input[i]
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 7(a0)       # load input[7 + i]
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49     # input[i] - '1'
    sb      t3, 0(a1)       # store p[i]

    addi    t4, t4, -49     # input[7 + i] - '1'
    sb      t4, 7(a1)       # store o[i]
    # i = 1
    lbu     t3, 1(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 8(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 1(a1)

    addi    t4, t4, -49
    sb      t4, 8(a1)
    # i = 2
    lbu     t3, 2(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 9(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 2(a1)

    addi    t4, t4, -49
    sb      t4, 9(a1)
    # i = 3
    lbu     t3, 3(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 10(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 3(a1)

    addi    t4, t4, -49
    sb      t4, 10(a1)
    # i = 4
    lbu     t3, 4(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 11(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 4(a1)

    addi    t4, t4, -49
    sb      t4, 11(a1)
    # i = 5
    lbu     t3, 5(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 12(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 5(a1)

    addi    t4, t4, -49
    sb      t4, 12(a1)
    # i = 6
    lbu     t3, 6(a0)
    bltu    t3, t0, invalid
    bltu    t1, t3, invalid

    lbu     t4, 13(a0)
    bltu    t4, t0, invalid
    bltu    t2, t4, invalid

    addi    t3, t3, -49
    sb      t3, 6(a1)

    addi    t4, t4, -49
    sb      t4, 13(a1)

    lbu     t3, 14(a0)      # load input[14]
    bne     t3, zero, invalid   # input[14] == '\0'

    mv      a0, a1
    j       valid           # tail jump to valid

    .globl heuristic
heuristic:
    add     t0, a3, a0      # t0 = permutation_table + p
    lbu     t0, 0(t0)       # load permutation_table[p]

    add     t1, a2, a1      # t1 = orientation_table + o
    lbu     t1, 0(t1)       # load orientation_table[o]

    bgeu    t1, t0, heuristic_use_o  # if t1 >= t0 then heuristic_use_o

    mv      a0, t0          # return p
    ret
heuristic_use_o:
    mv      a0, t1          # return o
    ret

    .globl depth_limit_dfs_iterative
depth_limit_dfs_iterative:
    addi    sp, sp, -256

    sw      s11, 240(sp)
    # Save callee-saved registers used by the iterative DFS.
    sw      s8, 192(sp)
    sw      s7, 196(sp)
    sw      s6, 200(sp)
    sw      s5, 204(sp)
    sw      s4, 208(sp)
    sw      s3, 212(sp)
    sw      s2, 216(sp)
    sw      s1, 220(sp)
    sw      s0, 224(sp)
    sw      ra, 228(sp)
    sw      s9, 232(sp)
    sw      s10, 236(sp)

    mv      s0, sp          # s0 = stack[0]
    mv      s11, s0         # s11 = current frame pointer
    li      s1, 0           # s1 = depth
    mv      s2, a1          # s2 = depth limit
    mv      s3, a2          # s3 = orientation heuristic table
    mv      s4, a3          # s4 = permutation heuristic table

    la      s7, path
    la      s8, move_face
    la      s9, asm_perm_transition
    la      s10, asm_ori_transition

    # ------------------------------------------------------------
    # Root frame layout (16 bytes):
    #   0..1 : permutation rank (uint16)
    #   2..3 : orientation rank (uint16)
    #   4    : next_move
    #   5    : forbidden face-group start (0,3,6; root=9)
    #   6..15: unused
    #
    # The input is still the original 14-byte cube state.
    # Rank it once when entering this depth-limited search.
    # ------------------------------------------------------------
    mv      s5, a0          # preserve input state pointer

    mv      a0, s5
    jal     ra, rank_permutation
    sh      a0, 0(s0)

    mv      a0, s5
    jal     ra, rank_orientation
    sh      a0, 2(s0)

    sb      zero, 4(s0)     # root.next_move = 0
    li      t0, 9
    sb      t0, 5(s0)       # root has no forbidden face group
dfs_loop:
    mv      a0, s11

    lbu     t1, 4(a0)       # next_move
    bne     t1, zero, next_move_bigger_than_MOVES

    # The frame already stores the ranks; no per-node re-ranking.
    lhu     s5, 0(a0)       # permutation rank
    lhu     s6, 2(a0)       # orientation rank

    # Goal test: solved iff both ranks are zero.
    bne     s5, zero, depth_equal_limit
    bne     s6, zero, depth_equal_limit

    la      t0, solution_depth
    sb      s1, 0(t0)
    li      a0, 1
dfs_return:
    lw      s8, 192(sp)
    lw      s7, 196(sp)
    lw      s6, 200(sp)
    lw      s5, 204(sp)
    lw      s4, 208(sp)
    lw      s3, 212(sp)
    lw      s2, 216(sp)
    lw      s1, 220(sp)
    lw      s0, 224(sp)
    lw      ra, 228(sp)
    lw      s9, 232(sp)
    lw      s10, 236(sp)
    lw      s11, 240(sp)

    addi    sp, sp, 256
    ret
depth_equal_limit:
    bne     s1, s2, heuristic_bigger_than_limit
    bne     s1, zero, depth_sub_one

    li      a0, 0
    j       dfs_return
depth_sub_one:
    addi    s1, s1, -1
    addi    s11, s11, -16
    j       next_move_bigger_than_MOVES
heuristic_bigger_than_limit:
    # h = max(permutation_table[p], orientation_table[o])
    add     t0, s4, s5
    lbu     t0, 0(t0)

    add     t1, s3, s6
    lbu     t1, 0(t1)

    bgeu    t1, t0, use_o

    add     t2, t0, s1
    j       max_p_and_o
use_o:
    add     t2, t1, s1
max_p_and_o:
    bgeu    s2, t2, next_move_bigger_than_MOVES
    bne     s1, zero, depth_sub_one

    li      a0, 0
    j       dfs_return
next_move_bigger_than_MOVES:
    mv      t0, s11
    lbu     t1, 4(t0)

    li      t2, 9
    bltu    t1, t2, check_depth_and_move_face
    bne     s1, zero, depth_sub_one

    li      a0, 0
    j       dfs_return
check_depth_and_move_face:
    # Byte 5 stores the first move index of the forbidden face group.
    lbu     t3, 5(t0)
    bne     t1, t3, dfs_apply_move

    # Moves of each face are contiguous:
    # 0..2=R, 3..5=B, 6..8=D.
    # Skip the complete forbidden group at once.
    addi    t1, t1, 3
    sb      t1, 4(t0)
    j       dfs_loop
dfs_apply_move:
    # Save selected move in the solution path.
    add     t5, s7, s1
    sb      t1, 0(t5)

    # ------------------------------------------------------------
    # Child permutation rank:
    #   perm_transition[parent_p][move]
    #
    # Each row has 9 uint16_t entries.
    # byte_offset = ((rank * 9) + move) * 2
    # rank * 9 = (rank << 3) + rank
    # ------------------------------------------------------------
    lhu     t2, 0(t0)       # parent permutation rank
    slli    t3, t2, 3
    add     t3, t3, t2      # rank * 9
    add     t3, t3, t1      # rank * 9 + move
    slli    t3, t3, 1       # * 2 bytes
    add     t3, s9, t3
    lhu     t4, 0(t3)       # child permutation rank

    # Child orientation rank.
    lhu     t2, 2(t0)       # parent orientation rank
    slli    t3, t2, 3
    add     t3, t3, t2      # rank * 9
    add     t3, t3, t1      # rank * 9 + move
    slli    t3, t3, 1       # * 2 bytes
    add     t3, s10, t3
    lhu     t5, 0(t3)       # child orientation rank

    # Calculate forbidden group start for the child.
    add     t3, s8, t1
    lbu     t3, 0(t3)       # face = 0/1/2
    slli    t6, t3, 1
    add     t3, t6, t3      # face * 3 = 0/3/6

    # Parent will try the following move when revisited.
    addi    t1, t1, 1
    sb      t1, 4(t0)

    # Enter child frame.
    addi    s1, s1, 1
    addi    s11, s11, 16
    addi    t0, t0, 16

    sh      t4, 0(t0)       # child permutation rank
    sh      t5, 2(t0)       # child orientation rank
    sb      zero, 4(t0)     # child.next_move = 0
    sb      t3, 5(t0)       # child forbidden group

    j       dfs_loop
    
    .globl  rubik_solve_asm
    .type   rubik_solve_asm, @function
    .align  2
rubik_solve_asm:
    addi    sp, sp, -48

    sw      ra, 44(sp)
    sw      s0, 40(sp)
    sw      s1, 36(sp)
    sw      s2, 32(sp)
    sw      s3, 28(sp)
    sw      s4, 24(sp)
    sw      s5, 20(sp)

    mv      s0, a0
    mv      s1, a1
    mv      s2, a2

    mv      a0, s0          # input string
    la      a1, state       # parsed state buffer
    jal     ra, parse_state

    beq     a0, zero, rubik_invalid
input_correct:
    la      a0, state
    jal     ra, rank_permutation
    mv      s3, a0          # s3 = p

    la      a0, state
    jal     ra, rank_orientation
    mv      s4, a0          # s4 = o

    mv      a0, s3
    mv      a1, s4
    la      a2, asm_orientation_table
    la      a3, asm_permutation_table
    jal     ra, heuristic

    mv      s5, a0          # s0 = start

loop_for_depth_limit_dfs_iterative:
    li      t0, 12
    bgeu    s5, t0, rubik_not_found

    la      a0, state
    mv      a1, s5
    la      a2, asm_orientation_table
    la      a3, asm_permutation_table
    jal     ra, depth_limit_dfs_iterative

    bne     a0, zero, rubik_solution
    addi    s5, s5, 1
    j       loop_for_depth_limit_dfs_iterative
rubik_solution:
    la      t0, solution_depth
    lbu     s3, 0(t0)           # s3 = solution_depth
    li      s4, 0               # i = 0
    la      s5, path            # s5 = path

    # required = 1 (for '\0')
    addi    t5, s3, 1           # 每個 move 至少 1 byte + '\0'

    beq     s3, zero, check_cap

    add     t5, t5, s3
    addi    t5, t5, -1          # 再加上 depth - 1 個空白
count_suffix_loop:
    beq     s4, s3, check_cap

    add     t0, s5, s4
    lbu     t1, 0(t0)           # t1 = path[i]

    la      t2, move_suffix
    add     t2, t2, t1
    lbu     t3, 0(t2)           # 0 / '2' / 39

    beq     t3, zero, no_suffix
    addi    t5, t5, 1           # 有 suffix，多 1 byte
no_suffix:
    addi    s4, s4, 1
    j       count_suffix_loop
check_cap:
    bltu    s2, t5, rubik_small_cap

    li      s4, 0               # 重設 i = 0，準備輸出
    mv      t6, s1              # t6 = out pointer
rubik_print_loop:
    beq     s4, s3, rubik_print_done

    add     t0, s5, s4
    lbu     t1, 0(t0)           # t1 = path[i]

    # 1. Get move character
    la      t2, move_chars
    add     t2, t2, t1
    lbu     t3, 0(t2)           # R / B / D

    sb      t3, 0(t6)           # *out = move character
    addi    t6, t6, 1           # out++

    # 2. Get suffix
    la      t2, move_suffix
    add     t2, t2, t1
    lbu     t4, 0(t2)           # 0 / '2' / 39

    beqz    t4, no_print_suffix

    sb      t4, 0(t6)           # *out = suffix
    addi    t6, t6, 1           # out++
no_print_suffix:
    addi    s4, s4, 1           # i++

    # 3. Add space between moves
    beq     s4, s3, rubik_print_done

    li      t0, 32              # ASCII space
    sb      t0, 0(t6)
    addi    t6, t6, 1

    j       rubik_print_loop
rubik_print_done:
    sb      zero, 0(t6)         # '\0'

    mv      a0, s3              # return solution_depth
    j       rubik_return
rubik_small_cap:
    beqz    s2, rubik_small_return

    sb      zero, 0(s1)         # cap > 0: out[0] = '\0'
rubik_small_return:
    li      a0, -2
    j       rubik_return
rubik_invalid:
    li      a0, -1
    j       rubik_return
rubik_not_found:
    li      a0, -1
    j       rubik_return
rubik_return:
    lw      s5, 20(sp)
    lw      s4, 24(sp)
    lw      s3, 28(sp)
    lw      s2, 32(sp)
    lw      s1, 36(sp)
    lw      s0, 40(sp)
    lw      ra, 44(sp)

    addi    sp, sp, 48
    ret
    .size   rubik_solve_asm, .-rubik_solve_asm
