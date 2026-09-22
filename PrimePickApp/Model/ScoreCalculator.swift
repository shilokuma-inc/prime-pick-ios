//
//  ScoreCalculator.swift
//  PrimePickApp
//

import Foundation

/// クイズのスコア計算ロジック
///
/// 1 問あたりの獲得点は次の式で求める。
///
///     獲得点 = round(基礎点 × 難易度係数 × コンボ倍率) + 速度ボーナス
///
/// 不正解の場合は獲得点 0 でコンボがリセットされる。
/// View から計算を追い出してテストできるようにするため、純粋な値型として実装している。
struct ScoreCalculator {
    // MARK: - 係数

    /// 正解 1 問あたりの基礎点
    static let basePoints = 100

    /// コンボ 1 段階あたりの倍率の増分
    static let comboMultiplierStep = 0.1

    /// コンボ倍率の上限。11 連続正解以降は 2.0 倍で頭打ちになる
    static let maxComboMultiplier = 2.0

    /// 速度ボーナスの上限点
    static let maxSpeedBonus = 50

    /// この秒数以内に解答すると速度ボーナスが満点になる
    static let fullSpeedBonusSeconds: TimeInterval = 1.0

    /// この秒数以上かかると速度ボーナスが 0 になる
    static let zeroSpeedBonusSeconds: TimeInterval = 6.0

    // MARK: - 進行中の状態

    /// 合計スコア
    private(set) var totalScore: Int = 0

    /// 現在の連続正解数
    private(set) var currentCombo: Int = 0

    /// このプレイ中の最大コンボ
    private(set) var maxCombo: Int = 0

    /// 正解数
    private(set) var correctCount: Int = 0

    init() {}

    // MARK: - 解答の反映

    /// 1 問分の解答を反映し、その問題で獲得した点を返す
    /// - Parameters:
    ///   - isCorrect: 解答が正解だったか
    ///   - difficulty: 出題中の難易度
    ///   - elapsedTime: 出題が表示されてから解答するまでの経過時間（秒）
    @discardableResult
    mutating func submit(isCorrect: Bool, difficulty: Difficulty, elapsedTime: TimeInterval) -> Int {
        guard isCorrect else {
            currentCombo = 0
            return 0
        }

        currentCombo += 1
        maxCombo = max(maxCombo, currentCombo)
        correctCount += 1

        let gainedPoints = Self.points(
            difficulty: difficulty,
            combo: currentCombo,
            elapsedTime: elapsedTime
        )
        totalScore = Self.addingClamped(totalScore, gainedPoints)
        return gainedPoints
    }

    // MARK: - 計算

    /// 難易度係数
    static func difficultyFactor(_ difficulty: Difficulty) -> Double {
        switch difficulty {
        case .easy:
            return 1.0
        case .normal:
            return 1.5
        case .hard:
            return 2.0
        }
    }

    /// 連続正解数に対応するコンボ倍率
    /// - Parameter combo: 1 始まりの連続正解数。1 連続目は 1.0 倍
    static func comboMultiplier(combo: Int) -> Double {
        guard combo > 1 else { return 1.0 }
        let raw = 1.0 + comboMultiplierStep * Double(combo - 1)
        return min(raw, maxComboMultiplier)
    }

    /// 経過時間に対応する速度ボーナス。`fullSpeedBonusSeconds` から `zeroSpeedBonusSeconds` の間を線形に補間する
    static func speedBonus(elapsedTime: TimeInterval) -> Int {
        // NaN が渡された場合はボーナスなしとして扱う
        guard elapsedTime.isFinite else { return 0 }
        if elapsedTime <= fullSpeedBonusSeconds { return maxSpeedBonus }
        if elapsedTime >= zeroSpeedBonusSeconds { return 0 }

        let ratio = (zeroSpeedBonusSeconds - elapsedTime) / (zeroSpeedBonusSeconds - fullSpeedBonusSeconds)
        let bonus = (Double(maxSpeedBonus) * ratio).rounded()
        return min(maxSpeedBonus, max(0, Int(bonus)))
    }

    /// 正解 1 問あたりの獲得点
    static func points(difficulty: Difficulty, combo: Int, elapsedTime: TimeInterval) -> Int {
        let rawPoints = Double(basePoints)
            * difficultyFactor(difficulty)
            * comboMultiplier(combo: combo)
        // Double から Int への変換でクラッシュしないよう、現実的な上限で丸めてから変換する
        let clamped = min(max(rawPoints.rounded(), 0), Double(Int.max / 2))
        return addingClamped(Int(clamped), speedBonus(elapsedTime: elapsedTime))
    }

    /// オーバーフローした場合は `Int.max` に張り付かせる加算
    private static func addingClamped(_ lhs: Int, _ rhs: Int) -> Int {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int.max : sum
    }
}
