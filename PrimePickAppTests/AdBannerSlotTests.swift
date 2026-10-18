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

    /// 一度も表示できていなければ枠を消し、表示できたあとの自動リフレッシュの失敗では残す
    func testCollapsesOnlyWhenNoAdWasReceived() {
        XCTAssertTrue(AdBannerSlot.collapsesOnFailure(hasReceivedAd: false))
        XCTAssertFalse(AdBannerSlot.collapsesOnFailure(hasReceivedAd: true))
    }

    /// 在庫切れのときに短い間隔でリクエストを繰り返さない
    func testRetryDelayIsNotTooShort() {
        XCTAssertGreaterThanOrEqual(AdBannerSlot.retryDelay, .seconds(30))
    }

    /// 撮影モードでは結果画面にも枠を出さない（結果画面のスクリーンショットのレイアウトを変えない）
    func testScreenshotDemoHidesResultBanners() {
        let eligibility = AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true)
        for placement in [AdPlacement.quizResult, .dailyChallengeResult] {
            let slot = AdBannerSlot.state(
                canShowBanner: eligibility.canShowBanner(at: placement),
                isReadyToLoadAds: true,
                didFailToLoad: false
            )
            XCTAssertEqual(slot, .hidden, "\(placement)")
        }
    }

    func testAdsAreNotReadyByDefault() {
        XCTAssertFalse(EnvironmentValues().isAdsReadyToLoad)
    }
}
