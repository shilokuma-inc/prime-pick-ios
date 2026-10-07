//
//  DailyChallengeCardStateTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeCardStateTests: XCTestCase {

    private let today = DailyChallengeDay(year: 2026, month: 10, day: 15)
    private let startedAt = Date(timeIntervalSince1970: 1_790_000_000)

    func testNotStartedToday() {
        let state = DailyChallengeCardState(records: [record(back: 1, answered: 10, correct: 7, completed: true)], today: today)
        XCTAssertEqual(state.status, .notStarted)
        XCTAssertTrue(state.isPlayable)
        // 今日まだ解いていなくても、昨日までの連続を出す
        XCTAssertEqual(state.streak, 1)
        XCTAssertEqual(state.dayNumber, today.dayNumber)
    }

    /// 強制終了・途中でやめた日は「未完了 3 / 10」
    func testIncompleteToday() {
        let state = DailyChallengeCardState(records: [record(back: 0, answered: 3, correct: 2, completed: false)], today: today)
        XCTAssertEqual(state.status, .incomplete(answeredCount: 3, questionCount: 10))
        XCTAssertFalse(state.isPlayable)
        XCTAssertEqual(state.streak, 0)
    }

    func testCompletedToday() {
        let records = [
            record(back: 0, answered: 10, correct: 8, completed: true),
            record(back: 1, answered: 10, correct: 4, completed: true)
        ]
        let state = DailyChallengeCardState(records: records, today: today)
        XCTAssertEqual(state.status, .completed(correctCount: 8, questionCount: 10))
        XCTAssertFalse(state.isPlayable)
        XCTAssertEqual(state.streak, 2)
    }

    func testNoRecords() {
        let state = DailyChallengeCardState(records: [], today: today)
        XCTAssertEqual(state.status, .notStarted)
        XCTAssertEqual(state.streak, 0)
    }

    private func record(back: Int, answered: Int, correct: Int, completed: Bool) -> DailyChallengeRecord {
        var record = DailyChallengeRecord.started(
            dayKey: today.adding(days: -back).dayKey,
            generatorVersion: 1,
            questionCount: 10,
            startedAt: startedAt
        )
        record.results = Array(repeating: .correct, count: correct)
            + Array(repeating: .incorrect, count: answered - correct)
            + Array(repeating: .unanswered, count: 10 - answered)
        record.completedAt = completed ? startedAt.addingTimeInterval(60) : nil
        return record
    }
}
