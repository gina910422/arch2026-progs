#include <stdint.h>

__attribute__((optimize("O0"))) uint64_t __muldi3(uint64_t a, uint64_t b)
{
    uint64_t result = 0;

    while (b) {
        if (b & 1)
            result += a;

        a <<= 1;
        b >>= 1;
    }

    return result;
}
