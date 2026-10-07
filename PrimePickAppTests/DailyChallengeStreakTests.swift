//
//  DailyChallengeStreakTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeStreakTests: XCTestCase {

    private let today = DailyChallengeDay(year: 2026, month: 10, day: 15)

    func testNoRecordsIsZero() {
        let streak = DailyChallengeStreak(completedDays: [DailyChallengeDay](), today: today)
        XCTAssertEqual(streak.current, 0)
        XCTAssertEqual(streak.longest, 0)
    }

    func testCountsConsecutiveDaysEndingToday() {
        let streak = DailyChallengeStreak(completedDays: days(back: 0...4), today: today)
        XCTAssertEqual(streak.current, 5)
        XCTAssertEqual(streak.longest, 5)
    }

    /// 今日まだ解いていなくても、昨日まで続いていれば切れていない
    func testNotYetPlayedTodayKeepsStreakFromYesterday() {
        let streak = DailyChallengeStreak(completedDays: days(back: 1...3), today: today)
        XCTAssertEqual(streak.current, 3)
    }

    /// 昨日も解いていなければ切れている
    func testMissingYesterdayBreaksStreak() {
        let streak = DailyChallengeStreak(completedDays: days(back: 2...6), today: today)
        XCTAssertEqual(streak.current, 0)
        XCTAssertEqual(streak.longest, 5)
    }

    func testGapResetsCurrentButKeepsLongest() {
        // 10 日前〜7 日前の 4 日連続、1 日空けて 5 日前〜今日の 6 日連続
        let streak = DailyChallengeStreak(completedDays: days(back: 7...10) + days(back: 0...5), today: today)
        XCTAssertEqual(streak.current, 6)
        XCTAssertEqual(streak.longest, 6)

        let older = DailyChallengeStreak(completedDays: days(back: 20...29) + days(back: 0...2), today: today)
        XCTAssertEqual(older.current, 3)
        XCTAssertEqual(older.longest, 10)
    }

    func testOrderAndDuplicatesDoNotMatter() {
        let shuffled = [today.adding(days: -1), today, today.adding(days: -2), today, today.adding(days: -1)]
        XCTAssertEqual(DailyChallengeStreak(completedDays: shuffled, today: today).current, 3)
    }

    func testStreakContinuesAcrossMonthAndYearEnd() {
        let newYear = DailyChallengeDay(year: 2027, month: 1, day: 1)
        let completed = (0...3).map { newYear.adding(days: -$0) }
        XCTAssertEqual(DailyChallengeStreak(completedDays: completed, today: newYear).current, 4)
    }

    /// 時計を戻して「今日」より後の記録がある場合、現在のストリークには数えない
    func testFutureDaysAreNotCountedInCurrent() {
        let completed = days(back: 0...1) + [today.adding(days: 3)]
        let streak = DailyChallengeStreak(completedDays: completed, today: today)
        XCTAssertEqual(streak.current, 2)
        XCTAssertEqual(streak.longest, 2)
    }

    // MARK: - 記録から

    /// 途中でやめた（未完了の）日は数えない。正解数は問わない
    func testRecordsCountOnlyCompletedDays() {
        let records = [
            record(back: 0, completed: true, correctCount: 0),
            record(back: 1, completed: true, correctCount: 10),
            record(back: 2, completed: false, correctCount: 3),
            record(back: 3, completed: true, correctCount: 5),
            record(back: 4, completed: true, correctCount: 5)
        ]
        let streak = DailyChallengeStreak(records: records, today: today)
        XCTAssertEqual(streak.current, 2)
        XCTAssertEqual(streak.longest, 2)
    }

    /// 今日始めて途中でやめても、昨日までの連続は表示する（今日は未完了なので数えない）
    func testIncompleteTodayKeepsStreakFromYesterday() {
        let records = [record(back: 0, completed: false, correctCount: 1)] + (1...3).map { record(back: $0, completed: true, correctCount: 7) }
        XCTAssertEqual(DailyChallengeStreak(records: records, today: today).current, 3)
    }

    private func record(back: Int, completed: Bool, correctCount: Int) -> DailyChallengeRecord {
        let startedAt = Date(timeIntervalSince1970: 1_790_000_000)
        var record = DailyChallengeRecord.started(
            dayKey: today.adding(days: -back).dayKey,
            generatorVersion: 1,
            questionCount: 10,
            startedAt: startedAt
        )
        record.results = Array(repeating: .correct, count: correctCount)
            + Array(repeating: completed ? .incorrect : .unanswered, count: 10 - correctCount)
        record.completedAt = completed ? startedAt.addingTimeInterval(60) : nil
        return record
    }

    /// `today` から `back` 日前の日
    private func days(back range: ClosedRange<Int>) -> [DailyChallengeDay] {
        range.map { today.adding(days: -$0) }
    }
}
