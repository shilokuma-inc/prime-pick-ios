//
//  QuizPlayFinisherTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizPlayFinisherTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: TimeAttackRecordStore!
    private var finisher: BestScorePlayFinisher!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "QuizPlayFinisherTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = TimeAttackRecordStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
        finisher = BestScorePlayFinisher(store: store)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// タイムアタックは達成日時つきで記録し、自己ベストを更新したかを返す
    func testTimeAttackRecordsScoreWithDate() {
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 1_200)))
        XCTAssertEqual(
            TimeAttackRecordStore(userDefaults: userDefaults).records(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard),
            [ScoreRecord(score: 1_200, achievedAt: Date(timeIntervalSince1970: 1_790_000_000))]
        )
    }

    /// 下回ったとき・同点のときは NEW RECORD! を出さないが、上位 10 件には残す
    func testLowerOrEqualScoreIsNotNewRecordButIsKept() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        finisher.finish(outcome(gameMode: mode, score: 800))

        XCTAssertFalse(finisher.finish(outcome(gameMode: mode, score: 700)))
        XCTAssertFalse(finisher.finish(outcome(gameMode: mode, score: 800)), "同点は更新としない")
        XCTAssertTrue(finisher.finish(outcome(gameMode: mode, score: 801)))
        XCTAssertEqual(store.records(gameMode: mode, difficulty: .hard).map(\.score), [801, 800, 800, 700])
    }

    /// 0 点は初回でも NEW RECORD! にしない
    func testZeroScoreIsNotNewRecord() {
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 0)))
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 1)))
    }

    /// 旧形式の自己ベストは判定に使わない。消したあとは最初に 1 点以上取ったプレイが NEW RECORD! になる
    func testLegacyBestScoreDoesNotAffectNewRecord() {
        userDefaults.set(5_000, forKey: "bestScore.timeAttack_60.Hard")
        store.removeLegacyBestScores()

        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 100)))
    }

    /// 練習モードはスコアを比べられないため記録せず、NEW RECORD! も出さない
    func testPracticeDoesNotRecordBestScore() {
        XCTAssertFalse(finisher.finish(outcome(gameMode: .practice, score: 1_200)))
        XCTAssertEqual(store.records(gameMode: .practice, difficulty: .hard), [])
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
