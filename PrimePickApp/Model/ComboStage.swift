//
//  ComboStage.swift
//  PrimePickApp
//

import SwiftUI

/// コンボの段階。段階が上がるたびに見た目・振動を一段ずつ強くする（Discussion #156 の 6 章）
///
/// 倍率の上限に届く 11 コンボを最終段階（MAX）にしている。
enum ComboStage: Int, Comparable, CaseIterable {
    /// 1〜2 コンボ（0 もここに含める）
    case normal
    /// 3〜5 コンボ
    case good
    /// 6〜10 コンボ
    case great
    /// 11 コンボ〜。倍率が上限の 2.0 倍に届いている
    case max

    /// Good が始まるコンボ数
    static let goodMinimumCombo = 3
    /// Great が始まるコンボ数
    static let greatMinimumCombo = 6
    /// MAX が始まるコンボ数
    static let maxMinimumCombo = 11

    /// Great 中の振動の強さ。6 コンボで下限、10 コンボで上限になるよう線形に上げる
    static let greatIntensityRange: ClosedRange<Double> = 0.6...1.0

    init(combo: Int) {
        switch combo {
        case Self.maxMinimumCombo...:
            self = .max
        case Self.greatMinimumCombo...:
            self = .great
        case Self.goodMinimumCombo...:
            self = .good
        default:
            self = .normal
        }
    }

    static func < (lhs: ComboStage, rhs: ComboStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 正解してコンボが `combo` になったときの振動
    static func correctFeedback(combo: Int) -> SensoryFeedback {
        switch ComboStage(combo: combo) {
        case .normal:
            return .impact(weight: .light)
        case .good:
            return .impact(weight: .medium)
        case .great:
            let steps = Double(maxMinimumCombo - 1 - greatMinimumCombo)
            let progress = Double(combo - greatMinimumCombo) / steps
            let intensity = greatIntensityRange.lowerBound
                + (greatIntensityRange.upperBound - greatIntensityRange.lowerBound) * progress
            return .impact(weight: .heavy, intensity: intensity)
        case .max:
            // 到達した瞬間だけ特別な振動にし、以降は最も強い衝撃を続ける
            return combo == maxMinimumCombo ? .success : .impact(weight: .heavy, intensity: 1.0)
        }
    }

    /// コンボが `oldCombo` から `newCombo` に変わったとき、段階が上がったか
    static func didStageUp(from oldCombo: Int, to newCombo: Int) -> Bool {
        ComboStage(combo: newCombo) > ComboStage(combo: oldCombo)
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
