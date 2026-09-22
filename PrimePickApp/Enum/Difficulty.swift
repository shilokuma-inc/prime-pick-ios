//
//  Difficulty.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

enum Difficulty: String {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"

    /// 画面に表示する難易度名
    var localizedTitle: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }

    /// 出題レンジを明示的に選んでいないときに使う既定のレンジ
    ///
    /// レンジ選択が追加される前の挙動をそのまま再現する。
    var defaultRange: QuizRange {
        switch self {
        case .easy:
            return .oneOrTwoDigits
        case .normal, .hard:
            return .threeDigits
        }
    }

    /// 2・3・5 の倍数を出題から除外するか
    ///
    /// 「一目で素数でないと分かる数」を弾くための条件であり、出題レンジとは独立している。
    var excludesMultiplesOfTwoThreeFive: Bool {
        self == .hard
    }
}
