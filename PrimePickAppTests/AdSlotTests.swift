//
//  AdSlotTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class AdSlotTests: XCTestCase {

    func testLoadsWhenAllowedAndReady() {
        XCTAssertEqual(AdSlot.state(canShowAds: true, isReadyToLoadAds: true, didFailToLoad: false), .loading)
    }

    /// 撮影モード・テスト実行中・その置き場所に出さない設定のときは、枠ごと出さない
    func testHiddenWhenAdsAreNotAllowed() {
        XCTAssertEqual(AdSlot.state(canShowAds: false, isReadyToLoadAds: true, didFailToLoad: false), .hidden)
    }

    /// 同意フローと SDK の初期化が済むまでは読み込まない
    func testHiddenBeforeStartupFinishes() {
        XCTAssertEqual(AdSlot.state(canShowAds: true, isReadyToLoadAds: false, didFailToLoad: false), .hidden)
    }

    /// 読み込めなかったら枠を消す
    func testHiddenAfterLoadFailure() {
        XCTAssertEqual(AdSlot.state(canShowAds: true, isReadyToLoadAds: true, didFailToLoad: true), .hidden)
    }

    /// 一度も表示できていなければ枠を消し、表示できたあとの自動リフレッシュの失敗では残す
    func testCollapsesOnlyWhenNoAdWasReceived() {
        XCTAssertTrue(AdSlot.collapsesOnFailure(hasReceivedAd: false))
        XCTAssertFalse(AdSlot.collapsesOnFailure(hasReceivedAd: true))
    }

    /// 在庫切れのときに短い間隔でリクエストを繰り返さない
    func testRetryDelayIsNotTooShort() {
        XCTAssertGreaterThanOrEqual(AdSlot.retryDelay, .seconds(30))
    }

    /// 撮影モードではどの置き場所にも枠を出さない（スクリーンショットのレイアウトを変えない）
    func testScreenshotDemoHidesAdsAtEveryPlacement() {
        let eligibility = AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true)
        for placement in AdPlacement.allCases {
            let slot = AdSlot.state(
                canShowAds: eligibility.canShowAds(at: placement),
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
