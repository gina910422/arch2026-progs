#include "gcd.h"

uint32_t gcd_u32(uint32_t a, uint32_t b)
{
    // 1. a 和 b 其中一個為 0
    // gcd(0, b) = b
    if (a == 0) {
        return b;
    }
    // gcd(a, 0) = a
    if (b == 0) {
        return a;
    }

    // 2. a 和 b 皆為偶數
    // gcd(2a, 2b) = 2 * gcd(a, b)
    unsigned shift = 0;  // 記錄 a、b 共同含有多少個 factor 2

    while (((a | b) & 1) == 0) {
        a >>= 1;
        b >>= 1;
        shift++;
    }

    // 3. a 和 b 為一奇一偶
    // 3.1. a 是偶數; b 是奇數
    // gcd(2a, b) = gcd(a, b)
    while ((a & 1) == 0) {
        a >>= 1;
    }
    // 3.2. a 是奇數; b 是偶數
    // gcd(a, 2b) = gcd(a, b)
    while ((b & 1) == 0) {
        b >>= 1;
    }

    // 4. a 和 b 皆為奇數
    // gcd(a, b) = gcd(a, b - a)
    while (b != 0) {
        if (b < a) {
            unsigned temp = a;
            a = b;
            b = temp;
        }
        b = b - a;  // odd - odd = even => 新的 b 是偶數
        if (b != 0) {
            while ((b & 1) == 0) {
                b >>= 1;
            }
        }
    }
    return a << shift;
}
