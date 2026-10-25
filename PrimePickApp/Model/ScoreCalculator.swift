//
//  ScoreCalculator.swift
//  PrimePickApp
//

import Foundation
import QuizCore

// スコアの計算は QuizKit の `ScoreCalculator` を使う（係数の既定値は prime-pick で調整した値のまま Kit に移した）。
// ここでは難易度から係数を決める部分と、難易度で呼べる窓口だけを持つ。

extension Difficulty {
    /// スコアの難易度係数（`QuizQuestion.scoreFactor`）
    var scoreFactor: Double {
        switch self {
        case .easy:
            return 1.0
        case .normal:
            return 1.5
        case .hard:
            return 2.0
        case .expert:
            return 2.5
        }
    }
}

extension ScoreCalculator {
    // MARK: - 係数（`ScoringConfiguration.standard` の値）

    static var basePoints: Int { ScoringConfiguration.standard.basePoints }
    static var comboMultiplierStep: Double { ScoringConfiguration.standard.comboMultiplierStep }
    static var maxComboMultiplier: Double { ScoringConfiguration.standard.maxComboMultiplier }
    static var maxSpeedBonus: Int { ScoringConfiguration.standard.maxSpeedBonus }
    static var fullSpeedBonusSeconds: TimeInterval { ScoringConfiguration.standard.fullSpeedBonusSeconds }
    static var zeroSpeedBonusSeconds: TimeInterval { ScoringConfiguration.standard.zeroSpeedBonusSeconds }
    static var timeAttackMissPenaltyFactor: Double { ScoringConfiguration.standard.timeAttackMissPenaltyFactor }
    static var timeAttackSpeedBonusMinimumCombo: Int { ScoringConfiguration.standard.timeAttackSpeedBonusMinimumCombo }

    // MARK: - 難易度で呼べる窓口

    /// 1 問分の解答を反映し、その問題でのスコアの増減を返す
    @discardableResult
    mutating func submit(isCorrect: Bool, difficulty: Difficulty, elapsedTime: TimeInterval) -> Int {
        submit(isCorrect: isCorrect, difficultyFactor: difficulty.scoreFactor, elapsedTime: elapsedTime)
    }

    /// 難易度係数
    static func difficultyFactor(_ difficulty: Difficulty) -> Double {
        difficulty.scoreFactor
    }

    /// 連続正解数に対応するコンボ倍率
    static func comboMultiplier(combo: Int) -> Double {
        ScoreCalculator().comboMultiplier(combo: combo)
    }

    /// 経過時間に対応する速度ボーナス
    static func speedBonus(elapsedTime: TimeInterval) -> Int {
        ScoreCalculator().speedBonus(elapsedTime: elapsedTime)
    }

    /// 正解 1 問あたりの獲得点
    static func points(
        difficulty: Difficulty,
        combo: Int,
        elapsedTime: TimeInterval,
        rule: ScoringRule = .practice
    ) -> Int {
        pointsBreakdown(difficulty: difficulty, combo: combo, elapsedTime: elapsedTime, rule: rule).total
    }

    /// 正解 1 問あたりの獲得点を、正解点・コンボボーナス・速度ボーナスに分けたもの
    static func pointsBreakdown(
        difficulty: Difficulty,
        combo: Int,
        elapsedTime: TimeInterval,
        rule: ScoringRule = .practice
    ) -> ScoreBreakdown {
        ScoreCalculator(rule: rule).pointsBreakdown(
            difficultyFactor: difficulty.scoreFactor,
            combo: combo,
            elapsedTime: elapsedTime
        )
    }

    /// 速度ボーナスが付くか。タイムアタックではコンボ 3 以上のときだけ付く
    static func earnsSpeedBonus(combo: Int, rule: ScoringRule) -> Bool {
        ScoreCalculator(rule: rule).earnsSpeedBonus(combo: combo)
    }

    /// 誤答 1 問あたりの減点（正の値）。練習モードは減点しないので 0
    static func missPenalty(difficulty: Difficulty, rule: ScoringRule) -> Int {
        ScoreCalculator(rule: rule).missPenalty(difficultyFactor: difficulty.scoreFactor)
    }
}
