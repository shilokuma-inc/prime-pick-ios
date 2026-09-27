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
/// 不正解の場合はコンボがリセットされる。ルール（`ScoringRule`）によって次の違いがある。
///
/// - 練習モード: 不正解の獲得点は 0。速度ボーナスは常に付く
/// - タイムアタック: 不正解で `基礎点 × 難易度係数 × 2` を減点する（スコアは 0 未満にならない）。
///   速度ボーナスはコンボ 3 以上のときだけ付く
///
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

    /// タイムアタックの誤答で減点する点の、`基礎点 × 難易度係数` に対する倍率
    static let timeAttackMissPenaltyFactor = 2.0

    /// タイムアタックで速度ボーナスが付き始めるコンボ数
    static let timeAttackSpeedBonusMinimumCombo = 3

    // MARK: - ルール

    /// 適用するスコアルール
    let rule: ScoringRule

    // MARK: - 進行中の状態

    /// 合計スコア
    private(set) var totalScore: Int = 0

    /// 現在の連続正解数
    private(set) var currentCombo: Int = 0

    /// このプレイ中の最大コンボ
    private(set) var maxCombo: Int = 0

    /// 正解数
    private(set) var correctCount: Int = 0

    /// 獲得点・減点の内訳の累計。リザルトで内訳を出すために持つ
    private(set) var breakdown = ScoreBreakdown()

    init(rule: ScoringRule = .practice) {
        self.rule = rule
    }

    // MARK: - 解答の反映

    /// 1 問分の解答を反映し、その問題でのスコアの増減を返す
    ///
    /// タイムアタックの誤答では負の値を返す。スコアが 0 で止まった場合は、実際に減った分だけを返す。
    /// - Parameters:
    ///   - isCorrect: 解答が正解だったか
    ///   - difficulty: 出題中の難易度
    ///   - elapsedTime: 出題が表示されてから解答するまでの経過時間（秒）
    @discardableResult
    mutating func submit(isCorrect: Bool, difficulty: Difficulty, elapsedTime: TimeInterval) -> Int {
        guard isCorrect else {
            currentCombo = 0
            let deducted = min(totalScore, Self.missPenalty(difficulty: difficulty, rule: rule))
            totalScore -= deducted
            breakdown.penalty = Self.addingClamped(breakdown.penalty, deducted)
            return -deducted
        }

        currentCombo += 1
        maxCombo = max(maxCombo, currentCombo)
        correctCount += 1

        let gained = Self.pointsBreakdown(
            difficulty: difficulty,
            combo: currentCombo,
            elapsedTime: elapsedTime,
            rule: rule
        )
        breakdown.correctPoints = Self.addingClamped(breakdown.correctPoints, gained.correctPoints)
        breakdown.comboBonus = Self.addingClamped(breakdown.comboBonus, gained.comboBonus)
        breakdown.speedBonus = Self.addingClamped(breakdown.speedBonus, gained.speedBonus)
        totalScore = Self.addingClamped(totalScore, gained.total)
        return gained.total
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
    static func points(
        difficulty: Difficulty,
        combo: Int,
        elapsedTime: TimeInterval,
        rule: ScoringRule = .practice
    ) -> Int {
        pointsBreakdown(difficulty: difficulty, combo: combo, elapsedTime: elapsedTime, rule: rule).total
    }

    /// 正解 1 問あたりの獲得点を、正解点・コンボボーナス・速度ボーナスに分けたもの
    ///
    /// 正解点は `基礎点 × 難易度係数`、コンボボーナスはコンボ倍率を掛けて増えた分。
    /// 丸めは倍率を掛けた後に 1 回だけ行い、従来の `points` と同じ合計になるようにしている。
    static func pointsBreakdown(
        difficulty: Difficulty,
        combo: Int,
        elapsedTime: TimeInterval,
        rule: ScoringRule = .practice
    ) -> ScoreBreakdown {
        let correctPoints = clampedInt(Double(basePoints) * difficultyFactor(difficulty))
        let pointsWithCombo = clampedInt(
            Double(basePoints) * difficultyFactor(difficulty) * comboMultiplier(combo: combo)
        )
        let bonus = earnsSpeedBonus(combo: combo, rule: rule) ? speedBonus(elapsedTime: elapsedTime) : 0
        return ScoreBreakdown(
            correctPoints: correctPoints,
            comboBonus: max(0, pointsWithCombo - correctPoints),
            speedBonus: bonus
        )
    }

    /// 速度ボーナスが付くか。タイムアタックではコンボ 3 以上のときだけ付く
    /// - Parameter combo: この問題の正解を含めた連続正解数
    static func earnsSpeedBonus(combo: Int, rule: ScoringRule) -> Bool {
        switch rule {
        case .practice:
            return true
        case .timeAttack:
            return combo >= timeAttackSpeedBonusMinimumCombo
        }
    }

    /// 誤答 1 問あたりの減点（正の値）。練習モードは減点しないので 0
    static func missPenalty(difficulty: Difficulty, rule: ScoringRule) -> Int {
        switch rule {
        case .practice:
            return 0
        case .timeAttack:
            return clampedInt(Double(basePoints) * difficultyFactor(difficulty) * timeAttackMissPenaltyFactor)
        }
    }

    /// Double から Int への変換でクラッシュしないよう、現実的な上限で丸めてから変換する
    private static func clampedInt(_ value: Double) -> Int {
        Int(min(max(value.rounded(), 0), Double(Int.max / 2)))
    }

    /// オーバーフローした場合は `Int.max` に張り付かせる加算
    fileprivate static func addingClamped(_ lhs: Int, _ rhs: Int) -> Int {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int.max : sum
    }
}

/// スコアの計算ルール
enum ScoringRule {
    /// 練習モード。誤答の減点なし・速度ボーナスは常に付く
    case practice
    /// タイムアタック。誤答で減点・速度ボーナスはコンボ 3 以上から
    case timeAttack
}

/// 獲得点・減点の内訳
struct ScoreBreakdown: Equatable {
    /// 正解点（`基礎点 × 難易度係数`）
    var correctPoints: Int = 0
    /// コンボ倍率によって増えた点
    var comboBonus: Int = 0
    /// 速度ボーナス
    var speedBonus: Int = 0
    /// 誤答で実際に減った点（正の値）。スコアが 0 で止まった分は含めない
    var penalty: Int = 0

    /// 獲得点の合計から減点を引いたもの
    var total: Int {
        let gained = ScoreCalculator.addingClamped(
            ScoreCalculator.addingClamped(correctPoints, comboBonus),
            speedBonus
        )
        return gained - penalty
    }
}
