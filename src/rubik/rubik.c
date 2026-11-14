#include "rubik.h"
#include "rubik_tables.h"

enum { CUBIES = 7, MOVES = 9 };

typedef struct {
    uint8_t p[CUBIES], o[CUBIES];
} state_t;

static const char *const move_names[MOVES] = {"R",  "R2", "R'", "B", "B2",
                                              "B'", "D",  "D2", "D'"};

static const uint8_t move_face[MOVES] = {
    0, 0, 0,  // R, R2, R'
    1, 1, 1,  // B, B2, B'
    2, 2, 2   // D, D2, D'
};

static uint8_t path[11];
static uint8_t solution_depth;

typedef struct {
    uint16_t p_rank;
    uint16_t o_rank;
    uint8_t next_move;
} dfs_frame_t;

static uint16_t rank_permutation(const state_t *state)
{
    uint16_t p = 0;
    uint8_t smaller;

    /* i = 0 */
    smaller = 0;
    for (uint8_t j = 1; j < CUBIES; ++j)
        if (state->p[j] < state->p[0])
            ++smaller;
    p = smaller;

    /* i = 1 */
    smaller = 0;
    for (uint8_t j = 2; j < CUBIES; ++j)
        if (state->p[j] < state->p[1])
            ++smaller;
    p = (p << 2) + (p << 1) + smaller;  // p * 6

    /* i = 2 */
    smaller = 0;
    for (uint8_t j = 3; j < CUBIES; ++j)
        if (state->p[j] < state->p[2])
            ++smaller;
    p = (p << 2) + p + smaller;  // p * 5

    /* i = 3 */
    smaller = 0;
    for (uint8_t j = 4; j < CUBIES; ++j)
        if (state->p[j] < state->p[3])
            ++smaller;
    p = (p << 2) + smaller;  // p * 4

    /* i = 4 */
    smaller = 0;
    for (uint8_t j = 5; j < CUBIES; ++j)
        if (state->p[j] < state->p[4])
            ++smaller;
    p = (p << 1) + p + smaller;  // p * 3

    /* i = 5 */
    smaller = 0;
    // for (uint8_t j = 6; j < CUBIES; ++j)
    if (state->p[6] < state->p[5])
        ++smaller;
    p = (p << 1) + smaller;  // p * 2

    return p;
}

static uint16_t rank_orientation(const state_t *state)
{
    uint16_t o = 0;

    for (uint8_t i = 0; i < 6; ++i)
        // o = o * 3U + state->o[i];
        o = (o << 1) + o + state->o[i];
    return o;
}

static int valid(const state_t *state)
{
    uint8_t sum = 0;

    for (uint8_t i = 0; i < CUBIES; ++i) {
        if (state->p[i] >= CUBIES || state->o[i] >= 3)
            return 0;
        for (uint8_t j = 0; j < i; ++j)
            if (state->p[j] == state->p[i])
                return 0;
        sum = (uint8_t) (sum + state->o[i]);
    }
    return sum == 0 || sum == 3 || sum == 6 || sum == 9 || sum == 12;
}

static int parse_state(const char *input, state_t *state)
{
    for (uint8_t i = 0; i < 14; ++i) {
        if (input[i] == '\0')
            return 0;
    }

    if (input[14] != '\0') {
        return 0;
    }

    for (uint8_t i = 0; i < CUBIES; ++i) {
        if (input[i] < '1' || input[i] > '7')
            return 0;

        if (input[7 + i] < '1' || input[7 + i] > '3')
            return 0;

        state->p[i] = (uint8_t) (input[i] - '1');
        state->o[i] = (uint8_t) (input[7 + i] - '1');
    }

    return valid(state);
}

static uint8_t heuristic(const uint16_t p,
                         const uint16_t o,
                         const uint8_t *orientation_table,
                         const uint8_t *permutation_table)
{
    uint8_t heuristic_p = permutation_table[p];
    uint8_t heuristic_o = orientation_table[o];

    return heuristic_p > heuristic_o ? heuristic_p : heuristic_o;
}

static int depth_limit_dfs_iterative(uint16_t start_p,
                                     uint16_t start_o,
                                     uint8_t limit,
                                     const uint8_t *orientation_table,
                                     const uint8_t *permutation_table)
{
    dfs_frame_t stack[12];
    stack[0].p_rank = start_p;
    stack[0].o_rank = start_o;
    stack[0].next_move = 0;
    uint8_t depth = 0;

    while (1) {
        if (stack[depth].next_move == 0) {
            uint16_t p = stack[depth].p_rank;
            uint16_t o = stack[depth].o_rank;

            if (p == 0 && o == 0) {
                solution_depth = depth;
                return 1;
            }

            if (depth == limit) {
                if (depth == 0) {
                    return 0;
                }
                // pop
                --depth;
                continue;
            }

            if (heuristic(p, o, orientation_table, permutation_table) + depth >
                limit) {
                if (depth == 0) {
                    return 0;
                }
                --depth;
                continue;
            }
        }

        if (stack[depth].next_move >= MOVES) {
            // pop
            if (depth == 0) {
                return 0;
            }
            --depth;
            continue;
        }

        uint8_t move = stack[depth].next_move;

        if (depth > 0 && move_face[move] == move_face[path[depth - 1]]) {
            stack[depth].next_move++;
            continue;
        }

        path[depth] = move;

        // state_t next_state = apply_move(stack[depth].state, move);

        uint16_t p = stack[depth].p_rank;
        uint16_t o = stack[depth].o_rank;

        uint16_t next_p = perm_transition[p][move];
        uint16_t next_o = ori_transition[o][move];

        stack[depth].next_move++;
        ++depth;
        stack[depth].p_rank = next_p;
        stack[depth].o_rank = next_o;
        stack[depth].next_move = 0;
    }
}

int rubik_solve(const char *state, char *out, size_t cap)
{
    state_t cube;

    // 1. Validate input
    if (state == NULL || !parse_state(state, &cube)) {
        return -1;
    }

    // 2. Convert cube state to ranks
    uint16_t start_p = rank_permutation(&cube);
    uint16_t start_o = rank_orientation(&cube);

    // 3. Find the shortest solution
    uint8_t start =
        heuristic(start_p, start_o, orientation_table, permutation_table);

    int found = 0;

    for (uint8_t limit = start; limit <= 11; ++limit) {
        if (depth_limit_dfs_iterative(start_p, start_o, limit,
                                      orientation_table, permutation_table)) {
            found = 1;
            break;
        }
    }
    if (!found) {
        return -1;
    }

    // 4. Calculate required buffer size
    size_t required = 1;  // Reserve one byte for '\0'

    for (uint8_t i = 0; i < solution_depth; ++i) {
        const char *name = move_names[path[i]];

        while (*name != '\0') {
            ++required;
            ++name;
        }

        if (i > 0) {
            ++required;  // Space between moves
        }
    }

    // 5. Check output capacity
    if (out == NULL || cap < required) {
        if (out != NULL && cap > 0) {
            out[0] = '\0';
        }

        return -2;
    }

    // 6. Write solution to out
    size_t pos = 0;

    for (uint8_t i = 0; i < solution_depth; ++i) {
        if (i > 0) {
            out[pos++] = ' ';
        }

        const char *name = move_names[path[i]];

        while (*name != '\0') {
            out[pos++] = *name++;
        }
    }

    out[pos] = '\0';

    return solution_depth;
}
