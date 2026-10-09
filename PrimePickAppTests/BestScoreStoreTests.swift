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
        XCTAssertTrue(store.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).isNewRecord)
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 500)
    }

    /// 0 点は祝わず、保存もしない
    func testZeroScoreIsNotNewRecord() {
        XCTAssertFalse(store.record(score: 0, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).isNewRecord)
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
    }

    func testOnlyHigherScoreUpdatesBest() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        store.record(score: 800, gameMode: mode, difficulty: .normal)

        XCTAssertFalse(store.record(score: 700, gameMode: mode, difficulty: .normal).isNewRecord)
        XCTAssertFalse(store.record(score: 800, gameMode: mode, difficulty: .normal).isNewRecord, "同点は更新としない")
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 800)

        XCTAssertTrue(store.record(score: 801, gameMode: mode, difficulty: .normal).isNewRecord)
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 801)
    }

    /// 制限時間ごと・難易度ごとに別々に保存する
    func testBestScoreIsSeparatedByModeAndDifficulty() {
        store.record(score: 1_000, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard)

        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .hard))
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .normal))
        XCTAssertTrue(store.record(score: 10, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard).isNewRecord)

        var keys: Set<String> = []
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                keys.insert(BestScoreStore.key(gameMode: .timeAttack(duration), difficulty: difficulty)!)
            }
        }
        XCTAssertEqual(keys.count, 12)
    }

    /// Expert は新しい区分なので、他の難易度の記録があっても 0 から取る
    func testExpertStartsWithoutBestScore() {
        let mode = GameMode.timeAttack(.sixtySeconds)
        store.record(score: 1_500, gameMode: mode, difficulty: .hard)

        XCTAssertEqual(BestScoreStore.key(gameMode: mode, difficulty: .expert), "bestScore.timeAttack_60.Expert")
        XCTAssertNil(store.bestScore(gameMode: mode, difficulty: .expert))
        XCTAssertTrue(store.record(score: 300, gameMode: mode, difficulty: .expert).isNewRecord)
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .expert), 300)
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .hard), 1_500)
    }

    /// 出題レンジの選択をなくしても保存キーは変えない。
    /// 以前のバージョンが保存した自己ベストを、そのまま読み出して更新できる（Discussion #255 Q5: 引き継ぐ）
    func testReadsBestScoreSavedByPreviousVersion() {
        userDefaults.set(1_200, forKey: "bestScore.timeAttack_60.Hard")
        userDefaults.set(800, forKey: "bestScore.timeAttack_15.Easy")
        userDefaults.set(950, forKey: "bestScore.timeAttack_30.Normal")

        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard), 1_200)
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.fifteenSeconds), difficulty: .easy), 800)
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .normal), 950)

        XCTAssertFalse(store.record(score: 1_100, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard).isNewRecord)
        XCTAssertTrue(store.record(score: 1_300, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard).isNewRecord)
        XCTAssertEqual(userDefaults.integer(forKey: "bestScore.timeAttack_60.Hard"), 1_300)
    }

    // MARK: - 自己ベストとの比べ（Discussion #223）

    func testRecordReturnsPreviousBest() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        XCTAssertEqual(
            store.record(score: 500, gameMode: mode, difficulty: .normal),
            BestScoreUpdate(score: 500, previousBest: nil, isNewRecord: true)
        )
        XCTAssertEqual(
            store.record(score: 300, gameMode: mode, difficulty: .normal),
            BestScoreUpdate(score: 300, previousBest: 500, isNewRecord: false)
        )
        XCTAssertEqual(
            store.record(score: 700, gameMode: mode, difficulty: .normal),
            BestScoreUpdate(score: 700, previousBest: 500, isNewRecord: true)
        )
    }

    /// 初回は比べる自己ベストが無いので差を出さない。0 点の初回も同じ
    func testFirstRecordHasNoComparison() {
        XCTAssertNil(store.record(score: 500, gameMode: .timeAttack(.fifteenSeconds), difficulty: .easy).comparison)
        XCTAssertNil(store.record(score: 0, gameMode: .timeAttack(.sixtySeconds), difficulty: .easy).comparison)
    }

    func testComparisonWithPreviousBest() {
        let mode = GameMode.timeAttack(.sixtySeconds)
        store.record(score: 1_000, gameMode: mode, difficulty: .hard)
        XCTAssertEqual(store.record(score: 750, gameMode: mode, difficulty: .hard).comparison, .below(by: 250))
        XCTAssertEqual(store.record(score: 1_000, gameMode: mode, difficulty: .hard).comparison, .tied)
        XCTAssertEqual(store.record(score: 1_200, gameMode: mode, difficulty: .hard).comparison, .updated(by: 200))
        // 更新後はその値と比べる
        XCTAssertEqual(store.record(score: 0, gameMode: mode, difficulty: .hard).comparison, .below(by: 1_200))
    }

    /// 履歴を始める前に保存した自己ベストとも比べる
    func testComparisonUsesBestSavedBeforeHistory() {
        userDefaults.set(950, forKey: "bestScore.timeAttack_30.Normal")
        XCTAssertEqual(
            store.record(score: 900, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal).comparison,
            .below(by: 50)
        )
    }

    // MARK: - リセット（Discussion #223）

    func testDeleteAllRemovesEveryCategory() {
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                store.record(score: 100, gameMode: .timeAttack(duration), difficulty: difficulty)
            }
        }
        store.deleteAll()
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                XCTAssertNil(store.bestScore(gameMode: .timeAttack(duration), difficulty: difficulty))
            }
        }
    }

    /// リセットしても他の設定（テーマなど）は残す
    func testDeleteAllKeepsOtherKeys() {
        userDefaults.set("dark", forKey: AppTheme.userDefaultsKey)
        store.record(score: 100, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)
        store.deleteAll()
        XCTAssertEqual(userDefaults.string(forKey: AppTheme.userDefaultsKey), "dark")
    }

    /// リセットした後は、初回と同じく 1 点以上で NEW RECORD! になる
    func testRecordAfterDeleteAllIsFirstRecord() {
        let mode = GameMode.timeAttack(.sixtySeconds)
        store.record(score: 1_000, gameMode: mode, difficulty: .hard)
        store.deleteAll()
        XCTAssertEqual(
            store.record(score: 300, gameMode: mode, difficulty: .hard),
            BestScoreUpdate(score: 300, previousBest: nil, isNewRecord: true)
        )
    }

    func testPracticeIsNotSaved() {
        XCTAssertFalse(store.record(score: 5_000, gameMode: .practice, difficulty: .easy).isNewRecord)
        XCTAssertNil(store.record(score: 5_000, gameMode: .practice, difficulty: .easy).comparison)
        XCTAssertNil(store.bestScore(gameMode: .practice, difficulty: .easy))
        XCTAssertNil(BestScoreStore.key(gameMode: .practice, difficulty: .easy))
    }
}
