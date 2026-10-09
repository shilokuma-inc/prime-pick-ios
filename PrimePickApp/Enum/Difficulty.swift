//
//  Difficulty.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

/// 難易度。出る数（範囲と 2・3・5 の倍数の除外）と見た目・スコア係数を決める
///
/// rawValue はタイムアタックの記録の保存キー（`TimeAttackRecordStore`）と Analytics の `difficulty` の値を兼ねるので変えない。
enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    /// 4 桁（1000〜9999）を出す 4 段階目（Discussion #255 Q2）
    case expert = "Expert"

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
        case .expert:
            return .fourDigits
        }
    }

    /// 2・3・5 の倍数を出題から除外するか
    ///
    /// 「一目で素数でないと分かる数」を弾くための条件。出題範囲（`range`）とあわせて出る数を決める。
    var excludesMultiplesOfTwoThreeFive: Bool {
        switch self {
        case .easy, .normal:
            return false
        case .hard, .expert:
            return true
        }
    }
}
