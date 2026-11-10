#include "bf16.h"

#define BF16_EXP_BIAS 127
#define BF16_NAN() 0x7FC0
#define BF16_ZERO() 0x0000

uint16_t bf16_from_f32(uint32_t f32bits)
{
    // special cases
    uint32_t exp = (f32bits >> 23) & 0xFF;

    if (exp == 0xFF) {
        return (uint16_t) (f32bits >> 16);
    }

    // round-to-nearest-even
    f32bits += 0x7FFF + ((f32bits >> 16) & 1);

    return (uint16_t) (f32bits >> 16);
}

uint16_t bf16_mul(uint16_t a, uint16_t b)
{
    uint16_t sign_a = (a >> 15) & 1;
    uint16_t sign_b = (b >> 15) & 1;
    int16_t exp_a = ((a >> 7) & 0xFF);
    int16_t exp_b = ((b >> 7) & 0xFF);
    uint16_t mant_a = a & 0x7F;
    uint16_t mant_b = b & 0x7F;

    uint16_t result_sign = sign_a ^ sign_b;

    // 1. special cases
    // 1.1. NaN / Inf * zero / Inf
    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        if (!exp_b && !mant_b)
            return BF16_NAN();
        return (result_sign << 15) | 0x7F80;
    }
    if (exp_b == 0xFF) {
        if (mant_b)
            return b;
        if (!exp_a && !mant_a)
            return BF16_NAN();
        return (result_sign << 15) | 0x7F80;
    }
    // 1.2. zero
    if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
        return result_sign << 15;

    int16_t exp_adjust = 0;
    if (!exp_a) {
        while (!(mant_a & 0x80)) {
            mant_a <<= 1;
            exp_adjust--;
        }
        exp_a = 1;
    } else
        mant_a |= 0x80;
    if (!exp_b) {
        while (!(mant_b & 0x80)) {
            mant_b <<= 1;
            exp_adjust--;
        }
        exp_b = 1;
    } else
        mant_b |= 0x80;

    uint32_t result_mant = (uint32_t) mant_a * mant_b;
    int32_t result_exp = (int32_t) exp_a + exp_b - BF16_EXP_BIAS + exp_adjust;

    if (result_mant & 0x8000) {
        result_mant = (result_mant >> 8) & 0x7F;
        result_exp++;
    } else
        result_mant = (result_mant >> 7) & 0x7F;

    if (result_exp >= 0xFF)
        return (result_sign << 15) | 0x7F80;
    if (result_exp <= 0) {
        if (result_exp < -6)
            return result_sign << 15;
        result_mant >>= (1 - result_exp);
        result_exp = 0;
    }

    return (result_sign << 15) | ((result_exp & 0xFF) << 7) |
           (result_mant & 0x7F);
}

uint16_t bf16_sqrt(uint16_t a)
{
    // 1. 拆欄位
    uint16_t sign = (a >> 15) & 1;
    uint16_t exp = (a >> 7) & 0xFF;
    uint16_t mant = a & 0x7F;

    // 2. 處理 special cases
    // 2.1 NaN / Inf
    if (exp == 0xFF) {
        if (mant)
            return a;
        if (sign)
            return BF16_NAN();
        return 0x7F80;
    }
    // 2.2 Zero
    if (!exp && !mant) {
        return BF16_ZERO();
    }
    // 2.3 Negative finite number
    if (sign) {
        return BF16_NAN();
    }
    // 2.4 Positive Subnormal
    if (!exp) {
        return BF16_ZERO();
    }

    // 3. 處理 normal
    // 3.1. mant
    mant |= 0x80;
    int32_t e = (int32_t) exp - BF16_EXP_BIAS;

    // 3.2. exponent
    // odd: sqrt(x) = sqrt(2*m) * 2^((e-1)/2)
    uint32_t m = mant;
    int32_t result_exp;

    if (e & 1) {
        m <<= 1;
        result_exp = ((e - 1) >> 1) + BF16_EXP_BIAS;
    }
    // even: sqrt(x) = sqrt(m) * 2^(e/2)
    else {
        result_exp =
            (e >> 1) + BF16_EXP_BIAS; /* Hint: a shift that halves it */
    }

    // 4. binary search 找 sqrt(m)
    // 要滿足：(result/128)^2 ≒ m/128 => (result^2)/128 ≒ m
    // 4.1. 設定範圍
    uint32_t low = 90, high = 256, result_mant = 128;
    // 4.2. 每次取中間 mid -> 算平方 sq
    // 比較 sq、m
    while (low <= high) {
        uint32_t mid = (low + high) >> 1;
        uint32_t sq = (mid * mid) / 128;
        // 目前 sq <= 當前 m，代表：mid 太小，平方小於目標 => 往右找
        if (sq <= m) {
            result_mant = mid;
            low = mid + 1;
        }
        // 目前 sq > 當前 m，代表：mid 太大，平方超過目標 => 往左找
        else {
            high = mid - 1;
        }
    }

    // 5. 組回 BFloat16
    return ((result_exp & 0xFF) << 7) | (result_mant & 0x7F);
}
