//
//  TimeAttackComparisonTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
@testable import PrimePickApp

final class TimeAttackComparisonTests: XCTestCase {

    /// スコアの高い順の上位の記録
    private func records(_ scores: [Int]) -> [ScoreRecord] {
        scores.enumerated().map { index, score in
            ScoreRecord(score: score, achievedAt: Date(timeIntervalSince1970: 1_790_000_000 + Double(index)))
        }
    }

    // MARK: - 自己ベストとの差

    func testUpdatedBest() {
        let comparison = TimeAttackComparison(score: 1_320, recordsBefore: records([1_000, 800]), previousScore: nil)
        XCTAssertEqual(comparison.best, .updated(by: 320))
        XCTAssertEqual(comparison.rank, 1)
    }

    /// 同点はベストの更新ではない（NEW RECORD! の判定と同じ）。並びは先に出した記録が上なので 2 位
    func testTiedBestIsRankedBelowEarlierRecord() {
        let comparison = TimeAttackComparison(score: 1_000, recordsBefore: records([1_000, 800]), previousScore: nil)
        XCTAssertEqual(comparison.best, .tied)
        XCTAssertEqual(comparison.rank, 2)
    }

    func testShortOfBest() {
        let comparison = TimeAttackComparison(score: 880, recordsBefore: records([1_000, 900, 800]), previousScore: nil)
        XCTAssertEqual(comparison.best, .short(by: 120))
        XCTAssertEqual(comparison.rank, 3)
    }

    /// 初めての記録は比べる自己ベストが無い
    func testNoBestToCompareOnFirstRecord() {
        let comparison = TimeAttackComparison(score: 500, recordsBefore: [], previousScore: nil)
        XCTAssertNil(comparison.best)
        XCTAssertEqual(comparison.rank, 1)
    }

    // MARK: - 順位

    /// 上位 10 件に入らなければ順位を出さない
    func testNoRankOutsideTopRecords() {
        let full = records(Array(stride(from: 1_000, to: 0, by: -100)))  // 1000, 900, …, 100 の 10 件
        XCTAssertNil(TimeAttackComparison(score: 100, recordsBefore: full, previousScore: nil).rank, "同点は後ろに入るので 11 位")
        XCTAssertEqual(TimeAttackComparison(score: 101, recordsBefore: full, previousScore: nil).rank, 10)
    }

    /// 0 点は上位に記録しないので順位を出さない
    func testNoRankForZeroScore() {
        let comparison = TimeAttackComparison(score: 0, recordsBefore: [], previousScore: nil)
        XCTAssertNil(comparison.rank)
        XCTAssertNil(comparison.best)
    }

    // MARK: - 前回との差

    func testPreviousDifference() {
        XCTAssertEqual(TimeAttackComparison(score: 700, recordsBefore: [], previousScore: 620).previousDifference, 80)
        XCTAssertEqual(TimeAttackComparison(score: 600, recordsBefore: [], previousScore: 640).previousDifference, -40)
        XCTAssertEqual(TimeAttackComparison(score: 640, recordsBefore: [], previousScore: 640).previousDifference, 0)
        XCTAssertNil(TimeAttackComparison(score: 640, recordsBefore: [], previousScore: nil).previousDifference)
    }
}
