//
//  PrimeFactorization.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2026/09/22.
//

import Foundation

/// 素因数分解のロジック。
/// View から切り離した純粋な型として実装しているため、単体テストから直接呼び出せる。
enum PrimeFactorization {
    /// 素因数を昇順の配列で返す。
    ///
    /// - `391` → `[17, 23]`
    /// - `8` → `[2, 2, 2]`
    /// - `397` → `[397]`（素数は自分自身のみ）
    /// - `1` 以下 → `[]`（素因数を持たない）
    ///
    /// 返り値の総積は必ず元の数と一致する（`1` 以下を除く）。
    static func factors(of number: Int) -> [Int] {
        guard number > 1 else { return [] }

        var remaining = number
        var factors: [Int] = []
        var divisor = 2

        while divisor * divisor <= remaining {
            while remaining % divisor == 0 {
                factors.append(divisor)
                remaining /= divisor
            }
            // 2 の次は 3、以降は奇数のみを試す
            divisor += (divisor == 2) ? 1 : 2
        }

        if remaining > 1 {
            factors.append(remaining)
        }
        return factors
    }

    /// 素数かどうか。
    ///
    /// 小さい素数による試し割りでふるったあと、決定的ミラー・ラビン判定にかける。
    /// 試し割りだけで判定すると計算量が `O(√n)` になり、出題レンジの桁数を増やすと
    /// 1 桁ごとに約 3.16 倍ずつ重くなってしまうため、`O(log³n)` のこちらを使う。
    static func isPrime(_ number: Int) -> Bool {
        guard number >= 2 else { return false }

        // 判定の基数に使う小さい素数で先に割ってしまう。
        // 1681 未満の数はこのふるいだけで結論が出る。
        for base in millerRabinBases {
            let smallPrime = Int(base)
            if number == smallPrime { return true }
            if number % smallPrime == 0 { return false }
        }
        // 37 以下の素因数を持たないことが確定しているので、
        // 37 の次の素数 41 の二乗未満ならこれ以上割れる余地がなく素数
        if number < 41 * 41 { return true }

        return passesMillerRabin(UInt64(number))
    }

    /// ミラー・ラビン判定に使う基数。
    ///
    /// この 12 個をすべて試せば 3.3 × 10²⁴ 未満の数について判定が決定的になることが知られている。
    /// `Int.max`（約 9.2 × 10¹⁸）はこの範囲に収まるので、確率的な誤判定は起こらない。
    private static let millerRabinBases: [UInt64] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

    /// ミラー・ラビン判定の本体。
    ///
    /// `number` は 37 以下の素因数を持たない 1681 以上の奇数であることが前提。
    private static func passesMillerRabin(_ number: UInt64) -> Bool {
        // number - 1 を 奇数 d と 2 の冪 2^r の積に分解する
        let exponentOfTwo = (number - 1).trailingZeroBitCount
        let oddPart = (number - 1) >> exponentOfTwo

        baseLoop: for base in millerRabinBases {
            var value = power(base, oddPart, modulo: number)
            if value == 1 || value == number - 1 { continue }

            // 二乗を繰り返しても number - 1 に到達しなければ合成数が確定する
            for _ in 1..<exponentOfTwo {
                value = multiply(value, value, modulo: number)
                if value == number - 1 { continue baseLoop }
            }
            return false
        }
        return true
    }

    /// `(a * b) % modulo`
    ///
    /// 積が 64bit に収まらないため、128bit 幅のまま剰余を求める。
    /// `a` と `b` が `modulo` 未満であれば商も `modulo` 未満になるので桁溢れしない。
    private static func multiply(_ a: UInt64, _ b: UInt64, modulo: UInt64) -> UInt64 {
        modulo.dividingFullWidth(a.multipliedFullWidth(by: b)).remainder
    }

    /// `(base ^ exponent) % modulo` を繰り返し二乗法で求める
    private static func power(_ base: UInt64, _ exponent: UInt64, modulo: UInt64) -> UInt64 {
        var result: UInt64 = 1
        var base = base % modulo
        var exponent = exponent

        while exponent > 0 {
            if exponent & 1 == 1 {
                result = multiply(result, base, modulo: modulo)
            }
            base = multiply(base, base, modulo: modulo)
            exponent >>= 1
        }
        return result
    }
}
