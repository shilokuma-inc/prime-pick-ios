//
//  GameModeTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class GameModeTests: XCTestCase {

    // MARK: - 制限時間

    func testPracticeHasNoTimeLimit() {
        XCTAssertNil(GameMode.practice.timeLimitSeconds)
        XCTAssertFalse(GameMode.practice.isTimeAttack)
    }

    func testTimeAttackReturnsSelectedDuration() {
        XCTAssertEqual(GameMode.timeAttack(.fifteenSeconds).timeLimitSeconds, 15)
        XCTAssertEqual(GameMode.timeAttack(.thirtySeconds).timeLimitSeconds, 30)
        XCTAssertEqual(GameMode.timeAttack(.sixtySeconds).timeLimitSeconds, 60)
    }

    func testTimeAttackIsTimeAttackForEveryDuration() {
        for duration in TimeAttackDuration.allCases {
            XCTAssertTrue(GameMode.timeAttack(duration).isTimeAttack)
        }
    }

    // MARK: - ミニ解説

    func testAnswerExplanationIsShownOnlyInPractice() {
        XCTAssertTrue(GameMode.practice.showsAnswerExplanation)
        for duration in TimeAttackDuration.allCases {
            XCTAssertFalse(GameMode.timeAttack(duration).showsAnswerExplanation)
        }
    }

    // MARK: - スコアルール

    func testScoringRuleIsTimeAttackOnlyForTimeAttack() {
        XCTAssertEqual(GameMode.practice.scoringRule, .practice)
        for duration in TimeAttackDuration.allCases {
            XCTAssertEqual(GameMode.timeAttack(duration).scoringRule, .timeAttack)
        }
    }

    // MARK: - 誤答のペナルティ

    func testMissPenaltyAppliesOnlyToTimeAttack() {
        XCTAssertEqual(GameMode.practice.missTimePenaltySeconds, 0)
        XCTAssertEqual(GameMode.practice.missInputLockDuration, 0)
        for duration in TimeAttackDuration.allCases {
            // 制限時間の長さによらず固定
            XCTAssertEqual(GameMode.timeAttack(duration).missTimePenaltySeconds, 2)
            XCTAssertEqual(GameMode.timeAttack(duration).missInputLockDuration, 0.5, accuracy: 0.0001)
        }
    }

    func testRemainingSecondsAfterMissSubtractsTwoSeconds() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 30), 28)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 3), 1)
    }

    /// 残り 2 秒以下で誤答したら 0（即タイムアップ）になり、負にはならない
    func testRemainingSecondsAfterMissStopsAtZero() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 2), 0)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 1), 0)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 0), 0)
    }

    func testPracticeRemainingSecondsIsUnchangedByMiss() {
        XCTAssertEqual(GameMode.practice.remainingSecondsAfterMiss(from: 10), 10)
    }

    // MARK: - 残り 5 秒の演出

    func testFinalCountdownStartsAtFiveSeconds() {
        for duration in TimeAttackDuration.allCases {
            let mode = GameMode.timeAttack(duration)
            XCTAssertFalse(mode.isInFinalCountdown(remainingSeconds: 6))
            XCTAssertTrue(mode.isInFinalCountdown(remainingSeconds: 5))
            XCTAssertTrue(mode.isInFinalCountdown(remainingSeconds: 1))
            // 0 秒はタイムアップ
            XCTAssertFalse(mode.isInFinalCountdown(remainingSeconds: 0))
        }
    }

    func testPracticeHasNoFinalCountdown() {
        XCTAssertFalse(GameMode.practice.isInFinalCountdown(remainingSeconds: 3))
    }

    // MARK: - モード選択の並び

    func testAllCasesIsPracticeFollowedByDurationsInAscendingOrder() {
        XCTAssertEqual(
            GameMode.allCases,
            [
                .practice,
                .timeAttack(.fifteenSeconds),
                .timeAttack(.thirtySeconds),
                .timeAttack(.sixtySeconds)
            ]
        )
    }

    func testIdIsUniqueForEveryCase() {
        let ids = GameMode.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: - モードの色

    func testPracticeAndTimeAttackHaveDifferentThemeColors() {
        XCTAssertEqual(GameMode.practice.themeColors, GameMode.practiceThemeColors)
        XCTAssertNotEqual(GameMode.practiceThemeColors, GameMode.timeAttackThemeColors)
    }

    /// タイムアタックは制限時間によらず同じ色
    func testTimeAttackThemeColorsAreSameForEveryDuration() {
        for duration in TimeAttackDuration.allCases {
            XCTAssertEqual(GameMode.timeAttack(duration).themeColors, GameMode.timeAttackThemeColors)
        }
    }

    /// デイリーはモード選択に並ばないが、時間無制限で練習と同じ進め方なので練習の色
    func testDailyChallengeUsesPracticeThemeColors() {
        XCTAssertEqual(GameMode.dailyChallenge.themeColors, GameMode.practiceThemeColors)
    }

    /// 選択中のカプセルは 2 色のグラデーションで塗る
    func testThemeColorsAreTwoColorGradient() {
        for mode in GameMode.allCases + [.dailyChallenge] {
            XCTAssertEqual(mode.themeColors.count, 2, "\(mode.id)")
            XCTAssertNotEqual(mode.themeColors.first, mode.themeColors.last, "\(mode.id)")
        }
    }
}
