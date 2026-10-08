//
//  QuizPlayFinisherTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizPlayFinisherTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var finisher: BestScorePlayFinisher!

    override func setUp() {
        super.setUp()
        // 実機の自己ベストを壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "QuizPlayFinisherTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        finisher = BestScorePlayFinisher(store: BestScoreStore(userDefaults: userDefaults))
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// タイムアタックは自己ベストを記録し、更新したかを返す
    func testTimeAttackRecordsBestScore() {
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 1_200)).isNewRecord)
        XCTAssertEqual(
            BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard),
            1_200
        )
        // 下回ったときは更新しない
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 800)).isNewRecord)
    }

    /// 練習モードはスコアを比べられないため記録せず、NEW RECORD! も出さない
    func testPracticeDoesNotRecordBestScore() {
        XCTAssertFalse(finisher.finish(outcome(gameMode: .practice, score: 1_200)).isNewRecord)
        XCTAssertNil(BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .practice, difficulty: .hard))
    }

    /// 結果画面に出す自己ベストとの比べを返す。初回は出さない
    func testFinishReturnsBestScoreComparison() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        XCTAssertEqual(finisher.finish(outcome(gameMode: mode, score: 900)), QuizPlayFinishResult(isNewRecord: true))
        XCTAssertEqual(
            finisher.finish(outcome(gameMode: mode, score: 600)),
            QuizPlayFinishResult(isNewRecord: false, bestScoreComparison: .below(by: 300))
        )
        XCTAssertEqual(
            finisher.finish(outcome(gameMode: mode, score: 1_000)),
            QuizPlayFinishResult(isNewRecord: true, bestScoreComparison: .updated(by: 100))
        )
    }

    /// 練習モードは自己ベストと比べない
    func testPracticeHasNoBestScoreComparison() {
        XCTAssertEqual(finisher.finish(outcome(gameMode: .practice, score: 1_200)), QuizPlayFinishResult())
    }

    // MARK: - 1 プレイの記録（Discussion #223）

    /// タイムアタックを終えたら 1 プレイの記録を 1 件残す
    func testTimeAttackSavesPlayRecord() {
        let recordStore = SwiftDataTimeAttackRecordStore.inMemory()
        let playedAt = Date(timeIntervalSince1970: 1_790_000_000)
        let finisher = BestScorePlayFinisher(
            store: BestScoreStore(userDefaults: userDefaults),
            recordStore: recordStore,
            now: { playedAt }
        )
        let outcome = QuizPlayOutcome(
            gameMode: .timeAttack(.thirtySeconds),
            difficulty: .normal,
            score: 1_500,
            correctCount: 2,
            answerRecords: [answerRecord(id: 0, isCorrect: true), answerRecord(id: 1, isCorrect: false), answerRecord(id: 2, isCorrect: true)],
            maxCombo: 1
        )

        XCTAssertTrue(finisher.finish(outcome).isNewRecord)

        XCTAssertEqual(recordStore.allRecords(), [
            TimeAttackPlayRecord(
                playedAt: playedAt,
                duration: .thirtySeconds,
                difficulty: .normal,
                score: 1_500,
                correctCount: 2,
                answeredCount: 3,
                maxCombo: 1
            )
        ])
        // 自己ベストもこれまでどおり記録する
        XCTAssertEqual(
            BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal),
            1_500
        )
    }

    /// 自己ベストを更新しなかったプレイ・0 点のプレイも記録に残す
    func testTimeAttackSavesEveryPlay() {
        let recordStore = SwiftDataTimeAttackRecordStore.inMemory()
        let finisher = BestScorePlayFinisher(store: BestScoreStore(userDefaults: userDefaults), recordStore: recordStore)

        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 800)).isNewRecord)
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 500)).isNewRecord)
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.fifteenSeconds), score: 0)).isNewRecord)

        XCTAssertEqual(recordStore.allRecords().map(\.score), [800, 500, 0])
    }

    /// 練習モードは記録を残さない（Discussion #223 Q5）
    func testPracticeDoesNotSavePlayRecord() {
        let recordStore = SwiftDataTimeAttackRecordStore.inMemory()
        let finisher = BestScorePlayFinisher(store: BestScoreStore(userDefaults: userDefaults), recordStore: recordStore)

        _ = finisher.finish(outcome(gameMode: .practice, score: 1_200))

        XCTAssertEqual(recordStore.allRecords(), [])
    }

    /// 途中でやめたプレイは記録を残さない
    func testAbandonedTimeAttackDoesNotSavePlayRecord() {
        let recordStore = SwiftDataTimeAttackRecordStore.inMemory()
        let finisher = BestScorePlayFinisher(store: BestScoreStore(userDefaults: userDefaults), recordStore: recordStore)

        finisher.abandon(outcome(gameMode: .timeAttack(.sixtySeconds), score: 1_200))

        XCTAssertEqual(recordStore.allRecords(), [])
        XCTAssertNil(BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard))
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

    private func answerRecord(id: Int, isCorrect: Bool) -> QuizAnswerRecord {
        QuizAnswerRecord(id: id, number: 7, isPrime: true, answeredPrime: isCorrect)
    }
}
