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
            XCTAssertTrue(eligibility.canShowAds(at: placement), "\(placement)")
        }
    }

    /// 撮影モードではスクリーンショットのレイアウトを変えないよう、枠ごと出さない
    func testNoAdsInScreenshotDemo() {
        let eligibility = eligibility(isScreenshotDemo: true)
        XCTAssertFalse(eligibility.isAdsEnabled)
        for placement in AdPlacement.allCases {
            XCTAssertFalse(eligibility.canShowAds(at: placement), "\(placement)")
        }
    }

    func testNoAdsWhileRunningTests() {
        let eligibility = eligibility(isRunningTests: true)
        XCTAssertFalse(eligibility.isAdsEnabled)
        XCTAssertFalse(eligibility.canShowAds(at: .quizResult))
    }

    func testNoAdsWithoutConfiguration() {
        let eligibility = eligibility(hasConfiguration: false)
        XCTAssertFalse(eligibility.isAdsEnabled)
        XCTAssertFalse(eligibility.canShowAds(at: .quizResult))
    }

    func testAdsOnlyAtEnabledPlacements() {
        let eligibility = eligibility(enabledPlacements: [.quizResult])
        XCTAssertTrue(eligibility.canShowAds(at: .quizResult))
        XCTAssertFalse(eligibility.canShowAds(at: .dailyChallengeResult))
    }

    /// 結果画面 2 つと設定画面に出す。ホーム（Discussion #376 で外した）と出題中には出さない
    func testDefaultPlacementsAreResultsAndSettings() {
        XCTAssertEqual(AdPlacement.enabled, [.quizResult, .dailyChallengeResult, .setting])
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
