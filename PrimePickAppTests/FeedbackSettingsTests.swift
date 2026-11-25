//
//  FeedbackSettingsTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class FeedbackSettingsTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // 実機の設定を壊さないよう、テストごとに使い捨ての領域を使う
        suiteName = "FeedbackSettingsTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 設定を触っていなければ、今までどおり効果音も振動も出す
    func testBothEnabledByDefault() {
        let settings = FeedbackSettings(userDefaults: userDefaults)

        XCTAssertTrue(settings.isSoundEnabled)
        XCTAssertTrue(settings.isHapticsEnabled)
    }

    /// 効果音と振動は別々に切れる
    func testSoundAndHapticsAreIndependent() {
        userDefaults.set(false, forKey: FeedbackSettings.isSoundEnabledKey)
        XCTAssertFalse(FeedbackSettings(userDefaults: userDefaults).isSoundEnabled)
        XCTAssertTrue(FeedbackSettings(userDefaults: userDefaults).isHapticsEnabled)

        userDefaults.set(true, forKey: FeedbackSettings.isSoundEnabledKey)
        userDefaults.set(false, forKey: FeedbackSettings.isHapticsEnabledKey)
        XCTAssertTrue(FeedbackSettings(userDefaults: userDefaults).isSoundEnabled)
        XCTAssertFalse(FeedbackSettings(userDefaults: userDefaults).isHapticsEnabled)
    }

    /// 設定画面のトグル（`@AppStorage`）と同じキーを読む。キーを変えると、オフにした人の設定が黙ってオンに戻る
    func testKeysAreStable() {
        XCTAssertEqual(FeedbackSettings.isSoundEnabledKey, "feedback.isSoundEnabled")
        XCTAssertEqual(FeedbackSettings.isHapticsEnabledKey, "feedback.isHapticsEnabled")
    }
}
