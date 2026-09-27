//
//  NumberExplanation.swift
//  PrimePickApp
//

import SwiftUI

/// 出題された数が素数かどうかの解説
///
/// リザルトの復習一覧と解答直後のミニ解説で同じ表現を使うため、表示内容をここに集約する。
enum NumberExplanation: Equatable {
    /// 素数（`17 は素数`）
    case prime(Int)
    /// 合成数と素因数（`91 = 7 × 13`）
    case composite(Int, factors: [Int])
    /// 素数でも合成数でもない数（`1` 以下）
    case neither(Int)

    init(number: Int) {
        let factors = PrimeFactorization.factors(of: number)
        if factors.count >= 2 {
            self = .composite(number, factors: factors)
        } else if factors.count == 1 {
            self = .prime(number)
        } else {
            // 1 以下は素因数を持たないため、合成数とは扱わない
            self = .neither(number)
        }
    }

    /// 画面に表示する文言
    var text: Text {
        switch self {
        case .prime(let number):
            return Text("\(number) is a prime number")
        case .composite(let number, let factors):
            let expression = factors.map(String.init).joined(separator: " × ")
            return Text(verbatim: "\(number) = \(expression)")
        case .neither(let number):
            return Text("\(number) is not a prime number")
        }
    }
}
