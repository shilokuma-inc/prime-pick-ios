//
//  ScoreCalculatorTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class ScoreCalculatorTests: XCTestCase {

    // MARK: - 難易度係数

    func testDifficultyFactorIncreasesWithDifficulty() {
        XCTAssertEqual(ScoreCalculator.difficultyFactor(.easy), 1.0, accuracy: 0.0001)
        XCTAssertEqual(ScoreCalculator.difficultyFactor(.normal), 1.5, accuracy: 0.0001)
        XCTAssertEqual(ScoreCalculator.difficultyFactor(.hard), 2.0, accuracy: 0.0001)
    }

    func testSameConditionScoresHigherOnHarderDifficulty() {
        let easy = ScoreCalculator.points(difficulty: .easy, combo: 1, elapsedTime: 0)
        let normal = ScoreCalculator.points(difficulty: .normal, combo: 1, elapsedTime: 0)
        let hard = ScoreCalculator.points(difficulty: .hard, combo: 1, elapsedTime: 0)
        XCTAssertLessThan(easy, normal)
        XCTAssertLessThan(normal, hard)
    }

    // MARK: - コンボ倍率

    func testComboMultiplierStartsAtOneAndGrows() {
        XCTAssertEqual(ScoreCalculator.comboMultiplier(combo: 1), 1.0, accuracy: 0.0001)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(combo: 2), 1.1, accuracy: 0.0001)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(combo: 5), 1.4, accuracy: 0.0001)
    }

    func testComboMultiplierIsCapped() {
        XCTAssertEqual(
            ScoreCalculator.comboMultiplier(combo: 11),
            ScoreCalculator.maxComboMultiplier,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            ScoreCalculator.comboMultiplier(combo: 10_000),
            ScoreCalculator.maxComboMultiplier,
            accuracy: 0.0001
        )
    }

    func testComboMultiplierIsOneForNonPositiveCombo() {
        XCTAssertEqual(ScoreCalculator.comboMultiplier(combo: 0), 1.0, accuracy: 0.0001)
        XCTAssertEqual(ScoreCalculator.comboMultiplier(combo: -5), 1.0, accuracy: 0.0001)
    }

    // MARK: - 速度ボーナス

    func testSpeedBonusIsMaxWithinFullBonusTime() {
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: 0), ScoreCalculator.maxSpeedBonus)
        XCTAssertEqual(
            ScoreCalculator.speedBonus(elapsedTime: ScoreCalculator.fullSpeedBonusSeconds),
            ScoreCalculator.maxSpeedBonus
        )
        // 端末時刻のずれなどで負の経過時間になっても上限を超えない
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: -10), ScoreCalculator.maxSpeedBonus)
    }

    func testSpeedBonusIsZeroAfterZeroBonusTime() {
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: ScoreCalculator.zeroSpeedBonusSeconds), 0)
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: 600), 0)
    }

    func testSpeedBonusInterpolatesLinearly() {
        // 1.0 秒 〜 6.0 秒 のちょうど中間なので上限の半分になる
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: 3.5), ScoreCalculator.maxSpeedBonus / 2)
    }

    func testSpeedBonusDecreasesMonotonically() {
        var previous = ScoreCalculator.maxSpeedBonus + 1
        for step in 0...80 {
            let bonus = ScoreCalculator.speedBonus(elapsedTime: Double(step) * 0.1)
            XCTAssertLessThanOrEqual(bonus, previous)
            XCTAssertGreaterThanOrEqual(bonus, 0)
            XCTAssertLessThanOrEqual(bonus, ScoreCalculator.maxSpeedBonus)
            previous = bonus
        }
    }

    func testSpeedBonusHandlesNonFiniteElapsedTime() {
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: .nan), 0)
        XCTAssertEqual(ScoreCalculator.speedBonus(elapsedTime: .infinity), 0)
    }

    // MARK: - 1 問あたりの獲得点

    func testPointsFollowsFormula() {
        // 100 × 1.0 × 1.0 + 50
        XCTAssertEqual(ScoreCalculator.points(difficulty: .easy, combo: 1, elapsedTime: 0), 150)
        // 100 × 2.0 × 2.0 + 0
        XCTAssertEqual(ScoreCalculator.points(difficulty: .hard, combo: 11, elapsedTime: 6.0), 400)
        // 100 × 1.5 × 1.2 + 25
        XCTAssertEqual(ScoreCalculator.points(difficulty: .normal, combo: 3, elapsedTime: 3.5), 205)
    }

    func testFasterAnswerScoresHigher() {
        let fast = ScoreCalculator.points(difficulty: .easy, combo: 1, elapsedTime: 0.5)
        let slow = ScoreCalculator.points(difficulty: .easy, combo: 1, elapsedTime: 5.0)
        XCTAssertGreaterThan(fast, slow)
    }

    func testPointsNeverNegativeForExtremeInput() {
        XCTAssertGreaterThanOrEqual(
            ScoreCalculator.points(difficulty: .easy, combo: Int.max, elapsedTime: .greatestFiniteMagnitude),
            0
        )
        XCTAssertGreaterThanOrEqual(
            ScoreCalculator.points(difficulty: .hard, combo: Int.min, elapsedTime: -.greatestFiniteMagnitude),
            0
        )
    }

    // MARK: - 解答の反映

    func testInitialStateIsEmpty() {
        let calculator = ScoreCalculator()
        XCTAssertEqual(calculator.totalScore, 0)
        XCTAssertEqual(calculator.currentCombo, 0)
        XCTAssertEqual(calculator.maxCombo, 0)
        XCTAssertEqual(calculator.correctCount, 0)
    }

    func testComboGrowsOnConsecutiveCorrectAnswers() {
        var calculator = ScoreCalculator()
        for expectedCombo in 1...5 {
            calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)
            XCTAssertEqual(calculator.currentCombo, expectedCombo)
        }
        XCTAssertEqual(calculator.maxCombo, 5)
        XCTAssertEqual(calculator.correctCount, 5)
    }

    func testIncorrectAnswerResetsComboAndScoresNothing() {
        var calculator = ScoreCalculator()
        calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)
        calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)
        let scoreBeforeMiss = calculator.totalScore

        let gained = calculator.submit(isCorrect: false, difficulty: .easy, elapsedTime: 0)

        XCTAssertEqual(gained, 0)
        XCTAssertEqual(calculator.currentCombo, 0)
        XCTAssertEqual(calculator.maxCombo, 2)
        XCTAssertEqual(calculator.correctCount, 2)
        XCTAssertEqual(calculator.totalScore, scoreBeforeMiss)
    }

    func testTotalScoreOfMixedSequence() {
        var calculator = ScoreCalculator()
        // 速度ボーナスが 0 になる経過時間を使い、コンボ倍率だけを検証する
        calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)   // 100
        calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)   // 110
        calculator.submit(isCorrect: false, difficulty: .easy, elapsedTime: 6.0)  // 0 / コンボリセット
        calculator.submit(isCorrect: true, difficulty: .easy, elapsedTime: 6.0)   // 100

        XCTAssertEqual(calculator.totalScore, 310)
        XCTAssertEqual(calculator.correctCount, 3)
        XCTAssertEqual(calculator.maxCombo, 2)
        XCTAssertEqual(calculator.currentCombo, 1)
    }

    func testConsecutiveCorrectAnswersAccelerateScoreGrowth() {
        var calculator = ScoreCalculator()
        var gains: [Int] = []
        for _ in 1...5 {
            gains.append(calculator.submit(isCorrect: true, difficulty: .normal, elapsedTime: 6.0))
        }
        for index in 1..<gains.count {
            XCTAssertGreaterThan(gains[index], gains[index - 1])
        }
    }

    func testLongStreakBeyondComboCapKeepsScoring() {
        // タイムアタックは 10 問固定ではなく問題が追加生成されるため、
        // コンボ上限を超えて解答が続いても破綻しないことを確認する
        var calculator = ScoreCalculator()
        var gains: [Int] = []
        for _ in 1...60 {
            gains.append(calculator.submit(isCorrect: true, difficulty: .hard, elapsedTime: 6.0))
        }

        // コンボ倍率が上限に達したあとは 1 問あたりの獲得点が一定になる
        XCTAssertEqual(Set(gains.suffix(40)).count, 1)
        XCTAssertEqual(calculator.currentCombo, 60)
        XCTAssertEqual(calculator.maxCombo, 60)
        XCTAssertEqual(calculator.correctCount, 60)
        XCTAssertEqual(calculator.totalScore, gains.reduce(0, +))
        XCTAssertGreaterThan(calculator.totalScore, 0)
    }

    func testTotalScoreNeverGoesNegativeOrOverflows() {
        var calculator = ScoreCalculator()
        for index in 0..<2_000 {
            calculator.submit(isCorrect: index % 7 != 0, difficulty: .hard, elapsedTime: 0)
            XCTAssertGreaterThanOrEqual(calculator.totalScore, 0)
        }
        XCTAssertLessThan(calculator.totalScore, Int.max)
        XCTAssertGreaterThan(calculator.totalScore, 0)
    }
}
