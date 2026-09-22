//
//  QuizRange.swift
//  PrimePickApp
//

import SwiftUI

/// 出題する数値の範囲
///
/// 難易度（`Difficulty`）が「出題される数の性質（2・3・5 の倍数を除くか）」と見た目を担うのに対し、
/// こちらは「どの桁数の数を出すか」だけを担う。
enum QuizRange: String, CaseIterable, Identifiable {
    /// 1 〜 99
    case oneOrTwoDigits = "1-99"
    /// 100 〜 999
    case threeDigits = "100-999"
    /// 1000 〜 9999
    case fourDigits = "1000-9999"

    var id: String { rawValue }

    /// 出題に使う閉区間
    var bounds: ClosedRange<Int> {
        switch self {
        case .oneOrTwoDigits:
            return 1...99
        case .threeDigits:
            return 100...999
        case .fourDigits:
            return 1000...9999
        }
    }

    /// この範囲で出題されうる最大の桁数
    var maxDigitCount: Int {
        bounds.upperBound.description.count
    }

    /// 画面に表示するレンジ名
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}
