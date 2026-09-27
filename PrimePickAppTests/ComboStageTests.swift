//
//  ComboStageTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class ComboStageTests: XCTestCase {

    // MARK: - 段階の境目

    func testStageBoundaries() {
        let expected: [(combo: Int, stage: ComboStage)] = [
            (0, .normal), (1, .normal), (2, .normal),
            (3, .good), (5, .good),
            (6, .great), (10, .great),
            (11, .max), (100, .max)
        ]
        for (combo, stage) in expected {
            XCTAssertEqual(ComboStage(combo: combo), stage, "combo=\(combo)")
        }
    }

    /// MAX はコンボ倍率が上限に届くコンボ数と一致させる
    func testMaxStageStartsWhenMultiplierIsCapped() {
        XCTAssertLessThan(
            ScoreCalculator.comboMultiplier(combo: ComboStage.maxMinimumCombo - 1),
            ScoreCalculator.maxComboMultiplier
        )
        XCTAssertEqual(
            ScoreCalculator.comboMultiplier(combo: ComboStage.maxMinimumCombo),
            ScoreCalculator.maxComboMultiplier,
            accuracy: 0.0001
        )
    }

    func testStagesAreOrdered() {
        XCTAssertLessThan(ComboStage.normal, .good)
        XCTAssertLessThan(ComboStage.good, .great)
        XCTAssertLessThan(ComboStage.great, .max)
    }

    // MARK: - 段階が上がったか

    func testDidStageUp() {
        XCTAssertTrue(ComboStage.didStageUp(from: 2, to: 3))
        XCTAssertTrue(ComboStage.didStageUp(from: 5, to: 6))
        XCTAssertTrue(ComboStage.didStageUp(from: 10, to: 11))
        XCTAssertFalse(ComboStage.didStageUp(from: 3, to: 4), "同じ段階の中では上がっていない")
        XCTAssertFalse(ComboStage.didStageUp(from: 11, to: 12))
        XCTAssertFalse(ComboStage.didStageUp(from: 7, to: 0), "コンボ切れは上がっていない")
    }

    func testAnnouncementOnlyForRaisedStages() {
        XCTAssertNil(ComboStage.normal.announcement)
        XCTAssertNotNil(ComboStage.good.announcement)
        XCTAssertNotNil(ComboStage.great.announcement)
        XCTAssertNotNil(ComboStage.max.announcement)
    }

    // MARK: - 振動

    func testCorrectFeedbackByStage() {
        XCTAssertEqual(ComboStage.correctFeedback(combo: 1), .impact(weight: .light))
        XCTAssertEqual(ComboStage.correctFeedback(combo: 2), .impact(weight: .light))
        XCTAssertEqual(ComboStage.correctFeedback(combo: 3), .impact(weight: .medium))
        XCTAssertEqual(ComboStage.correctFeedback(combo: 6), .impact(weight: .heavy, intensity: 0.6))
        XCTAssertEqual(ComboStage.correctFeedback(combo: 10), .impact(weight: .heavy, intensity: 1.0))
        // MAX に到達した瞬間だけ .success
        XCTAssertEqual(ComboStage.correctFeedback(combo: 11), .success)
        XCTAssertEqual(ComboStage.correctFeedback(combo: 12), .impact(weight: .heavy, intensity: 1.0))
    }

    func testIncorrectFeedbackIsError() {
        XCTAssertEqual(AnswerFeedback.incorrect.sensoryFeedback(combo: 0), .error)
        XCTAssertEqual(AnswerFeedbackTrigger(id: 1, result: .incorrect).sensoryFeedback, .error)
        XCTAssertEqual(AnswerFeedbackTrigger(id: 2, result: .correct, combo: 3).sensoryFeedback, .impact(weight: .medium))
    }
}
