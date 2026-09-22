//
//  PrimeData.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import Foundation

/// 素数判定
///
/// 従来はレンジ内の素数を毎回全件生成していたが、4 桁まで広げると現実的な速度が出ないため、
/// 与えられた 1 つの数だけを判定する純粋関数に置き換えている。
/// View に依存しないため、そのまま単体テストできる。
enum PrimeData {
    /// `number` が素数かどうかを返す
    ///
    /// 2・3 で割り切れるかを先に見たうえで、6k ± 1 の候補だけを √number まで試し割りする。
    static func isPrime(_ number: Int) -> Bool {
        if number < 2 { return false }
        if number < 4 { return true }          // 2, 3
        if number % 2 == 0 || number % 3 == 0 { return false }

        var divisor = 5
        while divisor * divisor <= number {
            if number % divisor == 0 || number % (divisor + 2) == 0 {
                return false
            }
            divisor += 6
        }
        return true
    }
}
