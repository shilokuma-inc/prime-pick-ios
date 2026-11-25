//
//  QuizPlayFinisherTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
@testable import PrimePickApp

final class QuizPlayFinisherTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: TimeAttackRecordStore!
    private var history: TimeAttackPlayHistoryStore!
    private var finisher: BestScorePlayFinisher!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "QuizPlayFinisherTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = TimeAttackRecordStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
        history = TimeAttackPlayHistoryStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
        finisher = BestScorePlayFinisher(store: store, history: history)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// タイムアタックは達成日時つきで記録し、自己ベストを更新したかを返す
    func testTimeAttackRecordsScoreWithDate() {
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 1_200)).isNewRecord)
        XCTAssertEqual(
            TimeAttackRecordStore(userDefaults: userDefaults).records(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard),
            [ScoreRecord(score: 1_200, achievedAt: Date(timeIntervalSince1970: 1_790_000_000))]
        )
    }

    /// 下回ったとき・同点のときは NEW RECORD! を出さないが、上位 10 件には残す
    func testLowerOrEqualScoreIsNotNewRecordButIsKept() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        finisher.finish(outcome(gameMode: mode, score: 800))

        XCTAssertFalse(finisher.finish(outcome(gameMode: mode, score: 700)).isNewRecord)
        XCTAssertFalse(finisher.finish(outcome(gameMode: mode, score: 800)).isNewRecord, "同点は更新としない")
        XCTAssertTrue(finisher.finish(outcome(gameMode: mode, score: 801)).isNewRecord)
        XCTAssertEqual(store.records(gameMode: mode, difficulty: .hard).map(\.score), [801, 800, 800, 700])
    }

    /// 0 点は初回でも NEW RECORD! にしない
    func testZeroScoreIsNotNewRecord() {
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 0)).isNewRecord)
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 1)).isNewRecord)
    }

    /// 旧形式の自己ベストは判定に使わない。消したあとは最初に 1 点以上取ったプレイが NEW RECORD! になる
    func testLegacyBestScoreDoesNotAffectNewRecord() {
        userDefaults.set(5_000, forKey: "bestScore.timeAttack_60.Hard")
        store.removeLegacyBestScores()

        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 100)).isNewRecord)
    }

    /// 練習モードはスコアを比べられないため記録せず、NEW RECORD! も比べも出さない
    func testPracticeDoesNotRecordBestScore() {
        XCTAssertEqual(finisher.finish(outcome(gameMode: .practice, score: 1_200)), QuizPlayFinishResult())
        XCTAssertEqual(store.records(gameMode: .practice, difficulty: .hard), [])
        XCTAssertEqual(history.entries(gameMode: .practice, difficulty: .hard), [])
    }

    // MARK: - それまでの記録との比べ（#549）

    /// 記録する前の上位・前回と比べた結果を返す
    func testTimeAttackReturnsComparisonWithRecordsBeforeThisPlay() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        finisher.finish(outcome(gameMode: mode, score: 900))
        finisher.finish(outcome(gameMode: mode, score: 600))

        let result = finisher.finish(outcome(gameMode: mode, score: 700))

        XCTAssertFalse(result.isNewRecord)
        XCTAssertEqual(result.timeAttackComparison?.best, .short(by: 200))
        XCTAssertEqual(result.timeAttackComparison?.rank, 2)
        XCTAssertEqual(result.timeAttackComparison?.previousDifference, 100)
    }

    /// 初めてのプレイは、比べる自己ベストも前回も無い
    func testFirstTimeAttackHasNothingToCompare() {
        let result = finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 500))

        XCTAssertTrue(result.isNewRecord)
        XCTAssertEqual(
            result.timeAttackComparison,
            TimeAttackComparison(score: 500, recordsBefore: [], previousScore: nil)
        )
        XCTAssertNil(result.timeAttackComparison?.best)
        XCTAssertNil(result.timeAttackComparison?.previousDifference)
    }

    /// 上位に入らないプレイや 0 点のプレイも、履歴には残す（次の「前回との差」と推移グラフに使う）
    func testEveryTimeAttackPlayIsKeptInHistory() {
        let mode = GameMode.timeAttack(.sixtySeconds)
        finisher.finish(outcome(gameMode: mode, score: 0))
        finisher.finish(outcome(gameMode: mode, score: 300))

        XCTAssertEqual(history.entries(gameMode: mode, difficulty: .hard).map(\.score), [0, 300])
        XCTAssertEqual(finisher.finish(outcome(gameMode: mode, score: 250)).timeAttackComparison?.previousDifference, -50)
    }

    private func outcome(gameMode: GameMode, score: Int) -> QuizPlayOutcome {
        QuizPlayOutcome(
            gameMode: gameMode,
            difficulty: .hard,
            score: score,
            correctCount: 0,
            answerRecords: []
        )
    }
}
