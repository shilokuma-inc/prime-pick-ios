//
//  TimeAttackBestScoresTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class TimeAttackBestScoresTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: TimeAttackRecordStore!

    override func setUp() {
        super.setUp()
        // 実機の記録を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "TimeAttackBestScoresTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = TimeAttackRecordStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 選んでいる制限時間の、難易度ごとの 1 位を返す。ほかの制限時間の記録は混ぜない
    func testBestScoresOfSelectedDuration() {
        store.record(score: 1_200, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        store.record(score: 2_480, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        store.record(score: 900, gameMode: .timeAttack(.thirtySeconds), difficulty: .hard)
        store.record(score: 5_000, gameMode: .timeAttack(.sixtySeconds), difficulty: .easy)

        let bestScores = TimeAttackBestScores.load(store: store, isScreenshotDemo: false)

        XCTAssertEqual(bestScores.bestScores(for: .timeAttack(.thirtySeconds)), [.easy: 2_480, .hard: 900])
        XCTAssertEqual(bestScores.bestScores(for: .timeAttack(.sixtySeconds)), [.easy: 5_000])
    }

    /// 記録が 1 件も無い制限時間でも、タイムアタックなら空を返す（ボタンには「記録なし」の行を出す）
    func testEmptyForTimeAttackWithoutRecords() {
        let bestScores = TimeAttackBestScores.load(store: store, isScreenshotDemo: false)

        XCTAssertEqual(bestScores.bestScores(for: .timeAttack(.fifteenSeconds)), [:])
    }

    /// 練習・デイリーはスコアを記録しないので、自己ベストの行を出さない
    func testNilForModesWithoutRecords() {
        store.record(score: 1_000, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        let bestScores = TimeAttackBestScores.load(store: store, isScreenshotDemo: false)

        XCTAssertNil(bestScores.bestScores(for: .practice))
        XCTAssertNil(bestScores.bestScores(for: .dailyChallenge))
    }

    /// 撮影モードでは、記録があっても出さない（スクリーンショットのホーム画面を変えない）
    func testNilInScreenshotDemo() {
        store.record(score: 1_000, gameMode: .timeAttack(.thirtySeconds), difficulty: .easy)
        let bestScores = TimeAttackBestScores.load(store: store, isScreenshotDemo: true)

        XCTAssertNil(bestScores.bestScores(for: .timeAttack(.thirtySeconds)))
    }

    /// 記録が増えたら、読み直した値は新しいベストになる（タイトルに戻ったときに読み直す）
    func testReloadReflectsNewRecord() {
        store.record(score: 1_000, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)
        let before = TimeAttackBestScores.load(store: store, isScreenshotDemo: false)
        store.record(score: 1_500, gameMode: .timeAttack(.thirtySeconds), difficulty: .normal)
        let after = TimeAttackBestScores.load(store: store, isScreenshotDemo: false)

        XCTAssertNotEqual(before, after)
        XCTAssertEqual(after.bestScores(for: .timeAttack(.thirtySeconds)), [.normal: 1_500])
    }
}
