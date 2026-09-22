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

    /// 素数かどうか。素因数が自分自身ひとつだけなら素数。
    static func isPrime(_ number: Int) -> Bool {
        factors(of: number).count == 1
    }
}
