//
//  BestScoreStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class BestScoreStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: BestScoreStore!

    override func setUp() {
        super.setUp()
        // 実機の自己ベストを壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "BestScoreStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = BestScoreStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testNoBestScoreBeforeFirstPlay() {
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
    }

    func testFirstPositiveScoreIsNewRecord() {
        XCTAssertTrue(store.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 500)
    }

    /// 0 点は祝わず、保存もしない
    func testZeroScoreIsNotNewRecord() {
        XCTAssertFalse(store.record(score: 0, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
    }

    func testOnlyHigherScoreUpdatesBest() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        store.record(score: 800, gameMode: mode, difficulty: .normal)

        XCTAssertFalse(store.record(score: 700, gameMode: mode, difficulty: .normal))
        XCTAssertFalse(store.record(score: 800, gameMode: mode, difficulty: .normal), "同点は更新としない")
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 800)

        XCTAssertTrue(store.record(score: 801, gameMode: mode, difficulty: .normal))
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 801)
    }

    /// 制限時間ごと・難易度ごとに別々に保存する
    func testBestScoreIsSeparatedByModeAndDifficulty() {
        store.record(score: 1_000, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard)

        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .hard))
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .normal))
        XCTAssertTrue(store.record(score: 10, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard))

        var keys: Set<String> = []
        for duration in TimeAttackDuration.allCases {
            for difficulty in [Difficulty.easy, .normal, .hard] {
                keys.insert(BestScoreStore.key(gameMode: .timeAttack(duration), difficulty: difficulty)!)
            }
        }
        XCTAssertEqual(keys.count, 9)
    }

    func testPracticeIsNotSaved() {
        XCTAssertFalse(store.record(score: 5_000, gameMode: .practice, difficulty: .easy))
        XCTAssertNil(store.bestScore(gameMode: .practice, difficulty: .easy))
        XCTAssertNil(BestScoreStore.key(gameMode: .practice, difficulty: .easy))
    }
}
