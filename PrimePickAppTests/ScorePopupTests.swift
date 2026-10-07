//
//  ScorePopupTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class ScorePopupTests: XCTestCase {

    // MARK: - スコアの増減

    func testGainShowsPlusAndFastOnlyWithSpeedBonus() {
        let fast = ScorePopup.score(id: 1, submission: ScoreBreakdown(correctPoints: 150, comboBonus: 45, speedBonus: 50))
        XCTAssertEqual(fast?.text, "+245")
        XCTAssertEqual(fast?.isFast, true)
        XCTAssertEqual(fast?.isNegative, false)

        let slow = ScorePopup.score(id: 2, submission: ScoreBreakdown(correctPoints: 100, comboBonus: 10))
        XCTAssertEqual(slow?.text, "+110")
        XCTAssertEqual(slow?.isFast, false)
    }

    func testPenaltyShowsMinusInRed() {
        let popup = ScorePopup.score(id: 1, submission: ScoreBreakdown(penalty: 300))
        XCTAssertEqual(popup?.text, "\u{2212}300")
        XCTAssertEqual(popup?.isNegative, true)
        XCTAssertEqual(popup?.isFast, false)
    }

    /// スコア 0 での誤答のように増減が無ければ出さない
    func testNoPopupWithoutScoreChange() {
        XCTAssertNil(ScorePopup.score(id: 1, submission: ScoreBreakdown()))
    }

    /// 実際の解答の流れで、ScoreCalculator の直前の内訳からポップアップが作れる
    func testPopupFromScoreCalculatorLastSubmission() {
        var calculator = ScoreCalculator(rule: .timeAttack)
        XCTAssertNil(calculator.lastSubmission)

        calculator.submit(isCorrect: true, difficulty: .normal, elapsedTime: 0)
        XCTAssertEqual(ScorePopup.score(id: 1, submission: calculator.lastSubmission!)?.text, "+150")

        calculator.submit(isCorrect: false, difficulty: .normal, elapsedTime: 0)
        // 150 点しかないので、減点 300 のうち実際に減った 150 だけを出す
        XCTAssertEqual(ScorePopup.score(id: 2, submission: calculator.lastSubmission!)?.text, "\u{2212}150")

        calculator.submit(isCorrect: false, difficulty: .normal, elapsedTime: 0)
        XCTAssertNil(ScorePopup.score(id: 3, submission: calculator.lastSubmission!))
    }

    // MARK: - 時間ペナルティ

    func testTimePenaltyShowsSeconds() {
        let popup = ScorePopup.time(id: 1, deductedSeconds: 2)
        XCTAssertEqual(popup?.text, "\u{2212}2s")
        XCTAssertEqual(popup?.isNegative, true)
    }

    /// 残り 1 秒で誤答した場合は、実際に減った 1 秒だけを出す。減っていなければ出さない
    func testTimePenaltyUsesActuallyDeductedSeconds() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        XCTAssertEqual(ScorePopup.time(id: 1, deductedSeconds: 1 - mode.remainingSecondsAfterMiss(from: 1))?.text, "\u{2212}1s")
        XCTAssertNil(ScorePopup.time(id: 2, deductedSeconds: 0))
    }
}
