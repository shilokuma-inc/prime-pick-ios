//
//  AdEligibilityTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AdEligibilityTests: XCTestCase {

    private func eligibility(
        isScreenshotDemo: Bool = false,
        isRunningTests: Bool = false,
        hasConfiguration: Bool = true,
        enabledPlacements: Set<AdPlacement> = AdPlacement.enabled
    ) -> AdEligibility {
        AdEligibility(
            isScreenshotDemo: isScreenshotDemo,
            isRunningTests: isRunningTests,
            hasConfiguration: hasConfiguration,
            enabledPlacements: enabledPlacements
        )
    }

    func testAdsAreEnabledInNormalLaunch() {
        let eligibility = eligibility()
        XCTAssertTrue(eligibility.isAdsEnabled)
        for placement in AdPlacement.allCases {
            XCTAssertTrue(eligibility.canShowBanner(at: placement), "\(placement)")
        }
    }

    /// 撮影モードではスクリーンショットのレイアウトを変えないよう、枠ごと出さない
    func testNoAdsInScreenshotDemo() {
        let eligibility = eligibility(isScreenshotDemo: true)
        XCTAssertFalse(eligibility.isAdsEnabled)
        for placement in AdPlacement.allCases {
            XCTAssertFalse(eligibility.canShowBanner(at: placement), "\(placement)")
        }
    }

    func testNoAdsWhileRunningTests() {
        let eligibility = eligibility(isRunningTests: true)
        XCTAssertFalse(eligibility.isAdsEnabled)
        XCTAssertFalse(eligibility.canShowBanner(at: .home))
    }

    func testNoAdsWithoutConfiguration() {
        let eligibility = eligibility(hasConfiguration: false)
        XCTAssertFalse(eligibility.isAdsEnabled)
        XCTAssertFalse(eligibility.canShowBanner(at: .home))
    }

    func testBannerOnlyAtEnabledPlacements() {
        let eligibility = eligibility(enabledPlacements: [.home])
        XCTAssertTrue(eligibility.canShowBanner(at: .home))
        XCTAssertFalse(eligibility.canShowBanner(at: .quizResult))
        XCTAssertFalse(eligibility.canShowBanner(at: .dailyChallengeResult))
    }

    /// ホームと 2 つの結果画面に出す（Discussion #348 の決定）
    func testDefaultPlacementsAreHomeAndResults() {
        XCTAssertEqual(AdPlacement.enabled, [.home, .quizResult, .dailyChallengeResult])
    }

    func testDetectsTestRunFromEnvironment() {
        XCTAssertTrue(AdEligibility.isRunningTests(environment: ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]))
        XCTAssertFalse(AdEligibility.isRunningTests(environment: [:]))
    }

    /// このテスト自体がテストホストで動いているので、実際の判定は広告を止める
    func testCurrentDisablesAdsWhileRunningTests() {
        XCTAssertTrue(AdEligibility.current.isRunningTests)
        XCTAssertFalse(AdEligibility.current.isAdsEnabled)
    }
}
