//
//  HomeSelectionStoreTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class HomeSelectionStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // 実機の選択を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "HomeSelectionStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    private func store(isScreenshotDemo: Bool = false) -> HomeSelectionStore {
        HomeSelectionStore(userDefaults: userDefaults, isScreenshotDemo: isScreenshotDemo)
    }

    /// 初めて起動したときは、今までと同じ練習・10 問
    func testDefaultsBeforeFirstSelection() {
        XCTAssertEqual(store().gameMode, .practice)
        XCTAssertEqual(store().questionCount, .ten)
    }

    /// 選んだモード・問題数は、作り直したストア（次の起動）でも読める
    func testRestoresSavedSelection() {
        store().save(gameMode: .timeAttack(.fifteenSeconds))
        store().save(questionCount: .twenty)

        XCTAssertEqual(store().gameMode, .timeAttack(.fifteenSeconds))
        XCTAssertEqual(store().questionCount, .twenty)
    }

    /// タイトル画面に並ぶモードは、どれも保存して戻せる
    func testEverySelectableModeRoundTrips() {
        for gameMode in GameMode.allCases {
            store().save(gameMode: gameMode)
            XCTAssertEqual(store().gameMode, gameMode)
        }
    }

    /// デイリーはタイトル画面で選ぶモードではないので、保存しない（前の選択が残る）
    func testDoesNotSaveDailyChallenge() {
        store().save(gameMode: .timeAttack(.sixtySeconds))
        store().save(gameMode: .dailyChallenge)

        XCTAssertEqual(store().gameMode, .timeAttack(.sixtySeconds))
    }

    /// 知らない値（なくした制限時間など）が残っていても、既定に戻して起動できる
    func testFallsBackWhenStoredValueIsUnknown() {
        userDefaults.set("timeAttack_45", forKey: HomeSelectionStore.gameModeKey)
        userDefaults.set(7, forKey: HomeSelectionStore.questionCountKey)

        XCTAssertEqual(store().gameMode, .practice)
        XCTAssertEqual(store().questionCount, .ten)
    }

    /// 撮影モードでは、保存した選択を読まず、選び直しても書かない（スクリーンショットのホーム画面を変えない）
    func testScreenshotDemoIgnoresSavedSelection() {
        store().save(gameMode: .timeAttack(.thirtySeconds))
        store().save(questionCount: .five)

        XCTAssertEqual(store(isScreenshotDemo: true).gameMode, .practice)
        XCTAssertEqual(store(isScreenshotDemo: true).questionCount, .ten)

        store(isScreenshotDemo: true).save(gameMode: .timeAttack(.sixtySeconds))
        store(isScreenshotDemo: true).save(questionCount: .twenty)
        XCTAssertEqual(store().gameMode, .timeAttack(.thirtySeconds))
        XCTAssertEqual(store().questionCount, .five)
    }
}
