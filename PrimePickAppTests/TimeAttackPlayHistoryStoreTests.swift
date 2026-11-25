//
//  TimeAttackPlayHistoryStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackPlayHistoryStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var currentDate: Date!
    private var store: TimeAttackPlayHistoryStore!

    override func setUp() {
        super.setUp()
        // 実機の履歴を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "TimeAttackPlayHistoryStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        currentDate = Date(timeIntervalSince1970: 1_790_000_000)
        store = TimeAttackPlayHistoryStore(userDefaults: userDefaults, now: { [unowned self] in currentDate })
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 1 プレイごとに 1 分進めて残す
    private func record(_ score: Int, gameMode: GameMode = .timeAttack(.thirtySeconds), difficulty: Difficulty = .easy) {
        currentDate = currentDate.addingTimeInterval(60)
        store.record(score: score, gameMode: gameMode, difficulty: difficulty)
    }

    func testEmptyBeforeFirstPlay() {
        XCTAssertEqual(store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), [])
        XCTAssertNil(store.lastScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
    }

    /// 遊んだ順（古い順）に、日時つきで残す。0 点も残す
    func testKeepsEveryPlayInOrder() {
        record(300)
        record(0)
        record(120)

        let entries = store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        XCTAssertEqual(entries.map(\.score), [300, 0, 120])
        XCTAssertEqual(entries.map(\.playedAt), [60, 120, 180].map { Date(timeIntervalSince1970: 1_790_000_000 + $0) })
        XCTAssertEqual(store.lastScore(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), 120)
    }

    /// 50 回を超えたら古いものから消す
    func testDropsOldestBeyondMaxEntryCount() {
        for score in 1...(TimeAttackPlayHistoryStore.maxEntryCount + 3) {
            record(score)
        }

        let scores = store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).map(\.score)
        XCTAssertEqual(scores.count, TimeAttackPlayHistoryStore.maxEntryCount)
        XCTAssertEqual(scores.first, 4)
        XCTAssertEqual(scores.last, TimeAttackPlayHistoryStore.maxEntryCount + 3)
    }

    /// 制限時間 × 難易度の枠ごとに分けて残す
    func testSeparatesSlots() {
        record(100, gameMode: .timeAttack(.fifteenSeconds), difficulty: .easy)
        record(200, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        record(300, gameMode: .timeAttack(.thirtySeconds), difficulty: .expert)

        XCTAssertEqual(store.entries(gameMode: .timeAttack(.fifteenSeconds), difficulty: .easy).map(\.score), [100])
        XCTAssertEqual(store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).map(\.score), [200])
        XCTAssertEqual(store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .expert).map(\.score), [300])
    }

    /// 練習・デイリーは残さない
    func testDoesNotKeepNonTimeAttackModes() {
        record(500, gameMode: .practice)
        record(500, gameMode: .dailyChallenge)

        XCTAssertEqual(store.entries(gameMode: .practice, difficulty: .easy), [])
        XCTAssertEqual(store.entries(gameMode: .dailyChallenge, difficulty: .easy), [])
        XCTAssertNil(TimeAttackPlayHistoryStore.key(gameMode: .practice, difficulty: .easy))
    }

    /// 保存のキーは上位 10 件（`timeAttackRecords.v1.*`）とは別。変えると、それまでの履歴が読めなくなる
    func testKeyFormat() {
        XCTAssertEqual(
            TimeAttackPlayHistoryStore.key(gameMode: .timeAttack(.sixtySeconds), difficulty: .hard),
            "timeAttackHistory.v1.timeAttack_60.Hard"
        )
    }

    /// 読めない（壊れている）値が残っていても、空として扱い、次のプレイから残し直す
    func testCorruptedDataIsTreatedAsEmpty() throws {
        let key = try XCTUnwrap(TimeAttackPlayHistoryStore.key(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy))
        userDefaults.set(Data("broken".utf8), forKey: key)

        XCTAssertEqual(store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy), [])
        record(10)
        XCTAssertEqual(store.entries(gameMode: .timeAttack(.thirtySeconds), difficulty: .easy).map(\.score), [10])
    }
}
