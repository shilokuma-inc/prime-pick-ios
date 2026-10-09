//
//  TimeAttackRecordStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackRecordStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var currentDate: Date!
    private var store: TimeAttackRecordStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "TimeAttackRecordStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        currentDate = Date(timeIntervalSince1970: 1_790_000_000)
        store = TimeAttackRecordStore(userDefaults: userDefaults, now: { [unowned self] in currentDate })
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 1 プレイごとに 1 分進めて記録する
    private func record(_ score: Int, gameMode: GameMode = .timeAttack(.thirtySeconds), difficulty: Difficulty = .easy) {
        currentDate = currentDate.addingTimeInterval(60)
        store.record(score: score, gameMode: gameMode, difficulty: difficulty)
    }

    // MARK: - 記録

    func testNoRecordsBeforeFirstPlay() {
        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), [])
        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
    }

    func testRecordKeepsAchievedDate() {
        record(500)

        XCTAssertEqual(
            store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy),
            [ScoreRecord(score: 500, achievedAt: Date(timeIntervalSince1970: 1_790_000_060))]
        )
    }

    /// スコアの高い順に並べ、同点は先に出した記録を上にする
    func testRecordsAreSortedByScoreThenEarlierFirst() {
        record(300)
        record(800)
        record(300)
        record(500)

        let records = store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        XCTAssertEqual(records.map(\.score), [800, 500, 300, 300])
        XCTAssertEqual(records[2].achievedAt, Date(timeIntervalSince1970: 1_790_000_060))
        XCTAssertEqual(records[3].achievedAt, Date(timeIntervalSince1970: 1_790_000_180))
    }

    /// 上位 10 件だけを残し、11 件目は落ちる
    func testKeepsOnlyTopTenRecords() {
        for score in 1...10 {
            record(score * 100)
        }
        record(50)
        XCTAssertEqual(
            store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).map(\.score),
            [1_000, 900, 800, 700, 600, 500, 400, 300, 200, 100]
        )

        record(150)
        XCTAssertEqual(
            store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).map(\.score),
            [1_000, 900, 800, 700, 600, 500, 400, 300, 200, 150]
        )

        // 10 位と同点は後から出したので入らない
        record(150)
        let records = store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        XCTAssertEqual(records.count, TimeAttackRecordStore.maxRecordCount)
        XCTAssertEqual(records.last?.achievedAt, Date(timeIntervalSince1970: 1_790_000_000 + 60 * 12))
    }

    /// 0 点は記録しない
    func testZeroScoreIsNotRecorded() {
        XCTAssertFalse(store.record(score: 0, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), [])
    }

    // MARK: - 自己ベストの更新

    func testFirstPositiveScoreIsNewBest() {
        XCTAssertTrue(store.record(score: 1, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 1)
    }

    func testOnlyHigherScoreUpdatesBest() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        store.record(score: 800, gameMode: mode, difficulty: .normal)

        XCTAssertFalse(store.record(score: 700, gameMode: mode, difficulty: .normal), "ベスト未満も記録はするが更新ではない")
        XCTAssertFalse(store.record(score: 800, gameMode: mode, difficulty: .normal), "同点は更新としない")
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 800)
        XCTAssertEqual(store.records(gameMode: mode, difficulty: .normal).map(\.score), [800, 800, 700])

        XCTAssertTrue(store.record(score: 801, gameMode: mode, difficulty: .normal))
        XCTAssertEqual(store.bestScore(gameMode: mode, difficulty: .normal), 801)
    }

    // MARK: - 枠

    /// 制限時間ごと・難易度ごとに別々に保存する
    func testRecordsAreSeparatedByDurationAndDifficulty() {
        record(1_000, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard)

        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .hard), [])
        XCTAssertEqual(store.records(gameMode: .timeAttack(.sixtySeconds), difficulty: .expert), [])
        XCTAssertTrue(store.record(score: 10, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard))
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard), 1_000)

        var keys: Set<String> = []
        for duration in TimeAttackDuration.allCases {
            for difficulty in Difficulty.allCases {
                keys.insert(TimeAttackRecordStore.key(gameMode: .timeAttack(duration), difficulty: difficulty)!)
            }
        }
        XCTAssertEqual(keys.count, 12)
    }

    /// 日付の無い旧形式とは別のキーに保存し、旧形式の値は読まない
    func testUsesKeySeparateFromLegacyBestScore() {
        XCTAssertEqual(
            TimeAttackRecordStore.key(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy),
            "timeAttackRecords.v1.timeAttack_30.Easy"
        )
        userDefaults.set(1_200, forKey: "bestScore.timeAttack_30.Easy")

        XCTAssertNil(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertTrue(store.record(score: 100, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertEqual(userDefaults.integer(forKey: "bestScore.timeAttack_30.Easy"), 1_200, "旧キーにはこのストアから触らない")
    }

    // MARK: - 旧形式の削除

    /// 日付の無い旧形式の自己ベストを 12 枠すべて消し、新しい記録とほかのキーは残す（Discussion #270 Q2）
    func testRemoveLegacyBestScoresRemovesAllTwelveKeys() {
        let legacyKeys = TimeAttackRecordStore.legacyBestScoreKeys
        XCTAssertEqual(Set(legacyKeys).count, 12)
        XCTAssertTrue(legacyKeys.contains("bestScore.timeAttack_15.Easy"))
        XCTAssertTrue(legacyKeys.contains("bestScore.timeAttack_60.Expert"))
        for (index, key) in legacyKeys.enumerated() {
            userDefaults.set(index + 1, forKey: key)
        }
        record(300)
        userDefaults.set("keep", forKey: "dailyChallenge.records.v1")

        store.removeLegacyBestScores()

        for key in legacyKeys {
            XCTAssertNil(userDefaults.object(forKey: key), key)
        }
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 300)
        XCTAssertEqual(userDefaults.string(forKey: "dailyChallenge.records.v1"), "keep")
    }

    /// 何度呼んでも、旧形式が無くても壊れない
    func testRemoveLegacyBestScoresIsIdempotent() {
        userDefaults.set(1_200, forKey: "bestScore.timeAttack_60.Hard")

        store.removeLegacyBestScores()
        store.removeLegacyBestScores()

        XCTAssertNil(userDefaults.object(forKey: "bestScore.timeAttack_60.Hard"))
        XCTAssertTrue(store.record(score: 100, gameMode: .timeAttack(.sixtySeconds), difficulty: .hard))
    }

    func testPracticeAndDailyChallengeAreNotSaved() {
        for mode in [GameMode.practice, .dailyChallenge] {
            XCTAssertNil(TimeAttackRecordStore.key(gameMode: mode, difficulty: .easy))
            XCTAssertFalse(store.record(score: 5_000, gameMode: mode, difficulty: .easy))
            XCTAssertEqual(store.records(gameMode: mode, difficulty: .easy), [])
            XCTAssertNil(store.bestScore(gameMode: mode, difficulty: .easy))
        }
    }

    // MARK: - 保存形式

    /// 別のインスタンス（アプリの再起動）からも読める
    func testRecordsPersistAcrossInstances() {
        record(700)

        let reloaded = TimeAttackRecordStore(userDefaults: userDefaults)
        XCTAssertEqual(
            reloaded.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy),
            [ScoreRecord(score: 700, achievedAt: Date(timeIntervalSince1970: 1_790_000_060))]
        )
    }

    /// 日時は UNIX 時間（秒）で保存し、知らない項目があっても読める
    func testDecodesStoredJSONWithUnknownFields() throws {
        let json = #"[{"achievedAt":1790000000,"score":900,"futureField":"x"}]"#
        userDefaults.set(Data(json.utf8), forKey: "timeAttackRecords.v1.timeAttack_15.Expert")

        XCTAssertEqual(
            store.records(gameMode: .timeAttack(.fifteenSeconds), difficulty: .expert),
            [ScoreRecord(score: 900, achievedAt: Date(timeIntervalSince1970: 1_790_000_000))]
        )
    }

    /// 壊れた記録は空として扱い、次の記録で上書きする
    func testCorruptedDataIsTreatedAsEmpty() {
        userDefaults.set(Data("broken".utf8), forKey: "timeAttackRecords.v1.timeAttack_30.Easy")

        XCTAssertEqual(store.records(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), [])
        XCTAssertTrue(store.record(score: 100, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        XCTAssertEqual(store.bestScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 100)
    }
}
