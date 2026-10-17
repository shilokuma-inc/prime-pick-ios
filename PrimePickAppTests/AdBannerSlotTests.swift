//
//  AdBannerSlotTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class AdBannerSlotTests: XCTestCase {

    func testLoadsWhenAllowedAndReady() {
        XCTAssertEqual(AdBannerSlot.state(canShowBanner: true, isReadyToLoadAds: true, didFailToLoad: false), .loading)
    }

    /// 撮影モード・テスト実行中・その置き場所に出さない設定のときは、枠ごと出さない
    func testHiddenWhenBannerIsNotAllowed() {
        XCTAssertEqual(AdBannerSlot.state(canShowBanner: false, isReadyToLoadAds: true, didFailToLoad: false), .hidden)
    }

    /// 同意フローと SDK の初期化が済むまでは読み込まない
    func testHiddenBeforeStartupFinishes() {
        XCTAssertEqual(AdBannerSlot.state(canShowBanner: true, isReadyToLoadAds: false, didFailToLoad: false), .hidden)
    }

    /// 読み込めなかったら枠を消す
    func testHiddenAfterLoadFailure() {
        XCTAssertEqual(AdBannerSlot.state(canShowBanner: true, isReadyToLoadAds: true, didFailToLoad: true), .hidden)
    }

    /// 撮影モードではホームに枠を出さない（スクリーンショットのレイアウトを変えない）
    func testScreenshotDemoHidesHomeBanner() {
        let eligibility = AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true)
        let slot = AdBannerSlot.state(
            canShowBanner: eligibility.canShowBanner(at: .home),
            isReadyToLoadAds: true,
            didFailToLoad: false
        )
        XCTAssertEqual(slot, .hidden)
    }

    func testAdsAreNotReadyByDefault() {
        XCTAssertFalse(EnvironmentValues().isAdsReadyToLoad)
    }
}
