//
//  TimeAttackRecordsViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackRecordsViewTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: TimeAttackRecordStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "TimeAttackRecordsViewTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = TimeAttackRecordStore(userDefaults: userDefaults, now: { Date(timeIntervalSince1970: 1_790_000_000) })
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 記録が無くても 15 / 30 / 60 秒の 3 枠を並べる（記録の無い枠は「—」で示す）
    func testSectionsListAllDurationsEvenWithoutRecords() {
        let sections = TimeAttackRecordsView.sections(store: store, difficulty: .easy)

        XCTAssertEqual(sections.map(\.duration), [.fifteenSeconds, .thirtySeconds, .sixtySeconds])
        XCTAssertTrue(sections.allSatisfy { $0.records.isEmpty })
    }

    /// 選んだ難易度の記録だけを、制限時間ごとにスコアの高い順で並べる
    func testSectionsShowRecordsOfSelectedDifficulty() {
        store.record(score: 500, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)
        store.record(score: 900, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)
        store.record(score: 1_200, gameMode: .timeAttack(.sixtySeconds), difficulty: .easy)

        let hard = TimeAttackRecordsView.sections(store: store, difficulty: .hard)
        XCTAssertEqual(hard[0].records, [])
        XCTAssertEqual(hard[1].records.map(\.score), [900, 500])
        XCTAssertEqual(hard[2].records, [])

        let easy = TimeAttackRecordsView.sections(store: store, difficulty: .easy)
        XCTAssertEqual(easy[2].records.map(\.score), [1_200])
    }
}
