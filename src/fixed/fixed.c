#include "fixed.h"

uint32_t op1(uint32_t a, uint32_t b, int *n)
{
    *n = 0;
    while (b) {
        unsigned c = (a & b) << 1;
        a = a ^ b;
        b = c;
        ++*n;
    }
    return a;
}

uint32_t op2(uint32_t a, uint32_t b)
{
    return a - b;
}

uint32_t op3(uint32_t a, uint32_t b)
{
    return (a >> 1) + (b >> 1) + (a & b & 1);
}

typedef int32_t qfixed_t;
typedef int64_t qbuf_t;

int32_t q_mul(int32_t a, int32_t b)
{
    return (qfixed_t) (((qbuf_t) a * b + (1 << (Q - 1))) >> Q);
}
