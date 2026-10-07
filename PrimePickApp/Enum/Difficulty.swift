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

    /// この難易度で出題する数の範囲
    ///
    /// 出る数は難易度だけで決める（Discussion #255）。Easy / Normal / Hard は、出題レンジの選択をなくす前の「おまかせ」と同じ。
    var range: QuizRange {
        switch self {
        case .easy:
            return .oneOrTwoDigits
        case .normal, .hard:
            return .threeDigits
        }
    }

    /// 2・3・5 の倍数を出題から除外するか
    ///
    /// 「一目で素数でないと分かる数」を弾くための条件。出題範囲（`range`）とあわせて出る数を決める。
    var excludesMultiplesOfTwoThreeFive: Bool {
        self == .hard
    }
}
