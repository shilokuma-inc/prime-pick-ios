//
//  DailyReminderSettingsTests.swift
//  PrimePickAppTests
//

import XCTest
import QuizCore
@testable import PrimePickApp

final class DailyReminderSettingsTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: DailyReminderSettingsStore!

    override func setUp() {
        super.setUp()
        // 実機の設定を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "DailyReminderSettingsTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = DailyReminderSettingsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 初めて起動した状態では、オフ・20:00・未案内・許可を求めていない
    func testDefaultsWhenNothingIsSaved() {
        let settings = store.load()
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.time, DailyReminderTime(hour: 20, minute: 0))
        XCTAssertFalse(settings.hasShownResultPrompt)
        XCTAssertFalse(settings.hasRequestedAuthorization)
        XCTAssertNil(settings.lastOpenedDay)
        XCTAssertEqual(settings, DailyReminderSettings())
    }

    func testSavedSettingsRoundTrip() throws {
        let settings = DailyReminderSettings(
            isEnabled: true,
            time: try XCTUnwrap(DailyReminderTime(hour: 7, minute: 45)),
            hasShownResultPrompt: true,
            hasRequestedAuthorization: true,
            lastOpenedDay: DailyChallengeDay(year: 2026, month: 11, day: 23)
        )
        store.save(settings)

        // 別のインスタンスからも読めること（＝ UserDefaults に保存されていること）
        XCTAssertEqual(DailyReminderSettingsStore(userDefaults: userDefaults).load(), settings)
    }

    func testUpdateChangesOnlyGivenFields() {
        store.update { $0.hasShownResultPrompt = true }
        store.update { $0.isEnabled = true }

        let settings = store.load()
        XCTAssertTrue(settings.isEnabled)
        XCTAssertTrue(settings.hasShownResultPrompt)
        XCTAssertFalse(settings.hasRequestedAuthorization)
        XCTAssertEqual(settings.time, .defaultTime)
    }

    func testClearingLastOpenedDayRemovesKey() {
        store.update { $0.lastOpenedDay = DailyChallengeDay(year: 2026, month: 11, day: 23) }
        store.update { $0.lastOpenedDay = nil }
        XCTAssertNil(userDefaults.object(forKey: DailyReminderSettingsStore.lastOpenedDayKey))
        XCTAssertNil(store.load().lastOpenedDay)
    }

    /// 壊れた時刻や日付は初期値として扱う
    func testInvalidStoredValuesFallBackToDefaults() {
        userDefaults.set(24, forKey: DailyReminderSettingsStore.hourKey)
        userDefaults.set(0, forKey: DailyReminderSettingsStore.minuteKey)
        userDefaults.set("2026-02-30", forKey: DailyReminderSettingsStore.lastOpenedDayKey)

        let settings = store.load()
        XCTAssertEqual(settings.time, .defaultTime)
        XCTAssertNil(settings.lastOpenedDay)
    }

    func testTimeRejectsOutOfRangeValues() {
        XCTAssertNotNil(DailyReminderTime(hour: 0, minute: 0))
        XCTAssertNotNil(DailyReminderTime(hour: 23, minute: 59))
        XCTAssertNil(DailyReminderTime(hour: 24, minute: 0))
        XCTAssertNil(DailyReminderTime(hour: -1, minute: 0))
        XCTAssertNil(DailyReminderTime(hour: 12, minute: 60))
    }
}
