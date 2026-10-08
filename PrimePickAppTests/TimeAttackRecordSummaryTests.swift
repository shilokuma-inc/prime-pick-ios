//
//  TimeAttackRecordSummaryTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackRecordSummaryTests: XCTestCase {

    // MARK: - TOP

    func testNoRecordsGivesEmptySummary() {
        let summary = TimeAttackRecordSummary(records: [])
        XCTAssertEqual(summary.top, [])
        XCTAssertEqual(summary.trend, [])
    }

    func testTopIsSortedByScoreDescending() {
        let records = [record(score: 300, playedAt: 1), record(score: 900, playedAt: 2), record(score: 600, playedAt: 3)]
        XCTAssertEqual(TimeAttackRecordSummary(records: records).top.map(\.score), [900, 600, 300])
    }

    func testTiedScoresPutEarlierPlayFirst() {
        let later = record(score: 500, playedAt: 20)
        let earlier = record(score: 500, playedAt: 10)
        XCTAssertEqual(TimeAttackRecordSummary(records: [later, earlier]).top, [earlier, later])
    }

    func testTopIsLimitedToTen() {
        let records = (1...15).map { record(score: $0 * 100, playedAt: TimeInterval($0)) }
        let top = TimeAttackRecordSummary(records: records).top
        XCTAssertEqual(top.count, TimeAttackRecordSummary.topLimit)
        XCTAssertEqual(top.first?.score, 1_500)
        XCTAssertEqual(top.last?.score, 600)
    }

    func testZeroScoreIsRanked() {
        let records = [record(score: 0, playedAt: 1), record(score: 200, playedAt: 2)]
        XCTAssertEqual(TimeAttackRecordSummary(records: records).top.map(\.score), [200, 0])
    }

    // MARK: - 推移

    func testTrendIsSortedOldestFirst() {
        let records = [record(score: 1, playedAt: 30), record(score: 2, playedAt: 10), record(score: 3, playedAt: 20)]
        XCTAssertEqual(TimeAttackRecordSummary(records: records).trend.map(\.score), [2, 3, 1])
    }

    func testTrendKeepsMostRecentTwenty() {
        let records = (1...25).map { record(score: $0, playedAt: TimeInterval($0)) }
        let trend = TimeAttackRecordSummary(records: records.shuffled()).trend
        XCTAssertEqual(trend.map(\.score), Array(6...25))
    }

    func testTrendWithFewRecordsKeepsAll() {
        let only = record(score: 400, playedAt: 1)
        XCTAssertEqual(TimeAttackRecordSummary(records: [only]).trend, [only])
    }

    // MARK: - Helpers

    private func record(score: Int, playedAt: TimeInterval) -> TimeAttackPlayRecord {
        TimeAttackPlayRecord(
            playedAt: Date(timeIntervalSince1970: playedAt),
            duration: .thirtySeconds,
            difficulty: .normal,
            score: score,
            correctCount: 5,
            answeredCount: 6,
            maxCombo: 3
        )
    }
}
