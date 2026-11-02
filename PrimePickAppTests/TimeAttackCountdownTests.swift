//
//  TimeAttackCountdownTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackCountdownTests: XCTestCase {
    private let advancedAt = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private let timeAttack = GameMode.timeAttack(.fifteenSeconds)

    private func countdown(_ remainingSeconds: Int, gameMode: GameMode? = nil) -> TimeAttackCountdown {
        TimeAttackCountdown(gameMode: gameMode ?? timeAttack, remainingSeconds: remainingSeconds, lastAdvancedAt: advancedAt)
    }

    private func date(after seconds: TimeInterval) -> Date {
        advancedAt.addingTimeInterval(seconds)
    }

    // MARK: - 実時間の残り時間

    func testRemainingTimeSubtractsElapsedTimeWithinSecond() {
        XCTAssertEqual(countdown(10).remainingTime(at: date(after: 0)), 10, accuracy: 1e-9)
        XCTAssertEqual(countdown(10).remainingTime(at: date(after: 0.25)), 9.75, accuracy: 1e-9)
    }

    func testRemainingTimeDoesNotGoBelowOneSecondLessThanWholeSeconds() {
        // バックグラウンドから戻ったとき・Timer が遅れたときは、次の .tick まで整数の残り秒の 1 秒手前で止める
        let remaining = countdown(4).remainingTime(at: date(after: 30))
        XCTAssertGreaterThan(remaining, 3)
        XCTAssertLessThan(remaining, 4)
        XCTAssertEqual(countdown(4).displayValue(at: date(after: 30)), .fractionalSeconds("3.00"))
    }

    func testRemainingTimeStaysAboveOneSecondLessForEveryWholeSecond() {
        for remainingSeconds in 1...60 {
            let remaining = countdown(remainingSeconds).remainingTime(at: date(after: 1.5))
            XCTAssertGreaterThan(remaining, TimeInterval(remainingSeconds - 1), "remainingSeconds=\(remainingSeconds)")
            XCTAssertLessThan(remaining, TimeInterval(remainingSeconds), "remainingSeconds=\(remainingSeconds)")
        }
    }

    func testDisplayWhenElapsedExceedsOneSecond() {
        // 残り 1 秒で .tick が遅れても 0.00 を出し、0 にはしない（タイムアップは QuizSession が決める）
        XCTAssertGreaterThan(countdown(1).remainingTime(at: date(after: 1.5)), 0)
        XCTAssertEqual(countdown(1).displayValue(at: date(after: 1.5)), .fractionalSeconds("0.00"))
        XCTAssertEqual(countdown(5).displayValue(at: date(after: 1.5)), .fractionalSeconds("4.00"))
        // 残り 6 秒は 5 秒より下に減らないので、整数のまま
        XCTAssertEqual(countdown(6).displayValue(at: date(after: 1.5)), .wholeSeconds(6))
    }

    func testRemainingTimeIgnoresDateBeforeLastAdvance() {
        XCTAssertEqual(countdown(4).remainingTime(at: date(after: -0.5)), 4, accuracy: 1e-9)
    }

    func testRemainingTimeKeepsElapsedTimeAfterPenalty() {
        // 誤答で整数の残り秒が 6 → 4 に減っても、最後の .tick からの経過はそのまま数える
        XCTAssertEqual(countdown(6).remainingTime(at: date(after: 0.3)), 5.7, accuracy: 1e-9)
        XCTAssertEqual(countdown(4).remainingTime(at: date(after: 0.3)), 3.7, accuracy: 1e-9)
        XCTAssertEqual(countdown(4).displayValue(at: date(after: 0.3)), .fractionalSeconds("3.70"))
    }

    func testRemainingTimeIsWholeSecondsBeforeStart() {
        let notStarted = TimeAttackCountdown(gameMode: timeAttack, remainingSeconds: 42, lastAdvancedAt: nil)
        XCTAssertEqual(notStarted.remainingTime(at: date(after: 0.5)), 42)
        XCTAssertEqual(notStarted.displayValue(at: date(after: 0.5)), .wholeSeconds(42))
    }

    func testRemainingTimeIsZeroAfterTimeUp() {
        XCTAssertEqual(countdown(0).remainingTime(at: date(after: 0.5)), 0)
    }

    // MARK: - 小数表示に切り替えるか

    func testSwitchesToFractionalJustBelowThreshold() {
        XCTAssertEqual(GameMode.timeAttackFractionalDisplayThresholdSeconds, 5)
        XCTAssertFalse(countdown(5).showsFractionalSeconds(at: date(after: 0)))
        XCTAssertEqual(countdown(5).displayValue(at: date(after: 0)), .wholeSeconds(5))
        XCTAssertTrue(countdown(5).showsFractionalSeconds(at: date(after: 0.01)))
        XCTAssertEqual(countdown(5).displayValue(at: date(after: 0.01)), .fractionalSeconds("4.99"))
    }

    func testKeepsWholeSecondsAboveThreshold() {
        XCTAssertFalse(countdown(6).showsFractionalSeconds(at: date(after: 0.99)))
        XCTAssertEqual(countdown(6).displayValue(at: date(after: 0.99)), .wholeSeconds(6))
        XCTAssertEqual(countdown(15).displayValue(at: date(after: 0.5)), .wholeSeconds(15))
    }

    func testThresholdBoundaryForGameMode() {
        XCTAssertFalse(timeAttack.showsFractionalRemainingTime(5))
        XCTAssertTrue(timeAttack.showsFractionalRemainingTime(4.999))
        XCTAssertTrue(timeAttack.showsFractionalRemainingTime(0))
    }

    func testPracticeAndDailyChallengeNeverShowFractionalSeconds() {
        for gameMode in [GameMode.practice, .dailyChallenge] {
            XCTAssertFalse(gameMode.showsFractionalRemainingTime(4.5), "\(gameMode)")
            XCTAssertFalse(gameMode.showsFractionalRemainingTime(0), "\(gameMode)")
            for remainingSeconds in [0, 3] {
                let practice = countdown(remainingSeconds, gameMode: gameMode)
                XCTAssertFalse(practice.showsFractionalSeconds(at: date(after: 0.5)), "\(gameMode)")
                XCTAssertEqual(practice.displayValue(at: date(after: 0.5)), .wholeSeconds(remainingSeconds), "\(gameMode)")
            }
        }
    }

    // MARK: - 毎フレームの描き直し

    func testUpdatesEveryFrameOnlyWithinFractionalRange() {
        XCTAssertFalse(countdown(6).updatesEveryFrame)
        for remainingSeconds in 1...5 {
            XCTAssertTrue(countdown(remainingSeconds).updatesEveryFrame, "remainingSeconds=\(remainingSeconds)")
        }
        // タイムアップの後は止める
        XCTAssertFalse(countdown(0).updatesEveryFrame)
    }

    func testDoesNotUpdateEveryFrameBeforeStart() {
        // 撮影モードは session.start() を呼ばないので、最後に進んだ時刻が無い
        let notStarted = TimeAttackCountdown(gameMode: timeAttack, remainingSeconds: 4, lastAdvancedAt: nil)
        XCTAssertFalse(notStarted.updatesEveryFrame)
    }

    func testPracticeAndDailyChallengeNeverUpdateEveryFrame() {
        XCTAssertFalse(countdown(3, gameMode: .practice).updatesEveryFrame)
        XCTAssertFalse(countdown(3, gameMode: .dailyChallenge).updatesEveryFrame)
    }

    // MARK: - プログレスバー

    func testProgressDecreasesWithElapsedTime() {
        let fifteen = countdown(15)
        XCTAssertEqual(fifteen.progress(at: date(after: 0)), 1, accuracy: 1e-9)
        XCTAssertEqual(fifteen.progress(at: date(after: 0.5)), 14.5 / 15, accuracy: 1e-9)
        XCTAssertLessThan(fifteen.progress(at: date(after: 0.5)), fifteen.progress(at: date(after: 0.25)))
    }

    func testProgressStopsOneSecondBeforeUntilNextTick() {
        // .tick が遅れても、整数の残り秒の 1 秒手前より下には減らない
        XCTAssertEqual(countdown(10).progress(at: date(after: 5)), 9.0 / 15, accuracy: 1e-9)
        XCTAssertGreaterThan(countdown(10).progress(at: date(after: 5)), 8.99 / 15)
    }

    func testProgressDropsByPenaltyAndKeepsElapsedTime() {
        XCTAssertEqual(countdown(8).progress(at: date(after: 0.4)), 7.6 / 15, accuracy: 1e-9)
        XCTAssertEqual(countdown(6).progress(at: date(after: 0.4)), 5.6 / 15, accuracy: 1e-9)
    }

    func testProgressUsesSelectedDuration() {
        let sixty = countdown(42, gameMode: .timeAttack(.sixtySeconds))
        XCTAssertEqual(sixty.progress(at: date(after: 0.5)), 41.5 / 60, accuracy: 1e-9)
    }

    func testProgressIsWholeSecondsBeforeStart() {
        // 撮影モードは残り 42 秒の位置で止めたまま
        let notStarted = TimeAttackCountdown(gameMode: .timeAttack(.sixtySeconds), remainingSeconds: 42, lastAdvancedAt: nil)
        XCTAssertEqual(notStarted.progress(at: date(after: 0.5)), 42.0 / 60, accuracy: 1e-9)
        XCTAssertFalse(notStarted.updatesProgressContinuously)
    }

    func testProgressIsZeroAfterTimeUp() {
        XCTAssertEqual(countdown(0).progress(at: date(after: 0.5)), 0)
        XCTAssertFalse(countdown(0).updatesProgressContinuously)
    }

    func testProgressUpdatesContinuouslyDuringTimeAttack() {
        XCTAssertTrue(countdown(15).updatesProgressContinuously)
        XCTAssertTrue(countdown(1).updatesProgressContinuously)
    }

    func testPracticeAndDailyChallengeKeepFixedProgress() {
        for gameMode in [GameMode.practice, .dailyChallenge] {
            let fixed = countdown(0, gameMode: gameMode)
            XCTAssertEqual(fixed.progress(at: date(after: 0.5)), 0.01, "\(gameMode)")
            XCTAssertFalse(fixed.updatesProgressContinuously, "\(gameMode)")
        }
    }

    // MARK: - 表示の整形

    func testFractionalTextTruncatesToTwoDigits() {
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 4.999), "4.99")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 0.004), "0.00")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 2.678), "2.67")
    }

    func testFractionalTextKeepsTrailingZeros() {
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 4.9), "4.90")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 2), "2.00")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 0), "0.00")
    }

    func testFractionalTextDoesNotTruncateBinaryRoundingErrors() {
        // 4.99 や 0.29 は 2 進数でわずかに小さく表されるが、1 つ下（4.98・0.28）に切り捨てない
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 4.99), "4.99")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 0.29), "0.29")
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 5 - 0.01), "4.99")
    }

    func testFractionalTextNeverReachesThreshold() {
        XCTAssertEqual(TimeAttackRemainingTimeDisplay.fractionalText(for: 5.0.nextDown), "4.99")
    }
}
