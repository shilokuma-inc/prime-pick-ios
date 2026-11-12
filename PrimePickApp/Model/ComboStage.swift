//
//  ComboStage.swift
//  PrimePickApp
//

import QuizCore
import SwiftUI

// コンボの段階（3 / 6 / 11 コンボの区切り）は QuizKit の `ComboStage` を使う（Discussion #156 の 6 章）。
// ここでは段階ごとの振動と読み上げの文言だけを持つ。

extension ComboStage {
    /// Great 中の振動の強さ。6 コンボで下限、10 コンボで上限になるよう線形に上げる
    static let greatIntensityRange: ClosedRange<Double> = 0.6...1.0

    /// 正解してコンボが `combo` になったときの振動
    static func correctFeedback(combo: Int) -> SensoryFeedback {
        switch ComboStage(combo: combo) {
        case .normal:
            return .impact(weight: .light)
        case .good:
            return .impact(weight: .medium)
        case .great:
            let intensity = greatIntensityRange.lowerBound
                + (greatIntensityRange.upperBound - greatIntensityRange.lowerBound) * greatProgress(combo: combo)
            return .impact(weight: .heavy, intensity: intensity)
        case .max:
            // 到達した瞬間だけ特別な振動にし、以降は最も強い衝撃を続ける
            return combo == maxMinimumCombo ? .success : .impact(weight: .heavy, intensity: 1.0)
        }
    }

    /// 段階が上がったときに VoiceOver で読み上げる文言。通常段階は読み上げない
    var announcement: LocalizedStringResource? {
        switch self {
        case .normal:
            return nil
        case .good:
            return "Good combo!"
        case .great:
            return "Great combo!"
        case .max:
            return "MAX combo!"
        }
    }
}
