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
        XCTAssertTrue(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 1_200)))
        XCTAssertEqual(
            BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard),
            1_200
        )
        // 下回ったときは更新しない
        XCTAssertFalse(finisher.finish(outcome(gameMode: .timeAttack(.sixtySeconds), score: 800)))
    }

    /// 練習モードはスコアを比べられないため記録せず、NEW RECORD! も出さない
    func testPracticeDoesNotRecordBestScore() {
        XCTAssertFalse(finisher.finish(outcome(gameMode: .practice, score: 1_200)))
        XCTAssertNil(BestScoreStore(userDefaults: userDefaults).bestScore(gameMode: .practice, difficulty: .hard))
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
