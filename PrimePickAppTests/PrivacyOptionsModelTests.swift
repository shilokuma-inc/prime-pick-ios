//
//  PrivacyOptionsModelTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

@MainActor
final class PrivacyOptionsModelTests: XCTestCase {

    private struct FormError: Error {}

    private final class FakePresenter: PrivacyOptionsPresenting {
        var isPrivacyOptionsRequired: Bool
        var error: Error?
        private(set) var presentCount = 0
        /// フォームを閉じたあとの `isPrivacyOptionsRequired`
        var isRequiredAfterPresent: Bool?

        init(isPrivacyOptionsRequired: Bool, error: Error? = nil) {
            self.isPrivacyOptionsRequired = isPrivacyOptionsRequired
            self.error = error
        }

        func presentPrivacyOptions() async throws {
            presentCount += 1
            if let isRequiredAfterPresent {
                isPrivacyOptionsRequired = isRequiredAfterPresent
            }
            if let error {
                throw error
            }
        }
    }

    private let enabled = AdEligibility(isScreenshotDemo: false, isRunningTests: false, hasConfiguration: true)

    func testVisibleOnlyWhenUMPRequiresPrivacyOptions() {
        XCTAssertTrue(PrivacyOptionsModel(eligibility: enabled, presenter: FakePresenter(isPrivacyOptionsRequired: true)).isVisible)
        XCTAssertFalse(PrivacyOptionsModel(eligibility: enabled, presenter: FakePresenter(isPrivacyOptionsRequired: false)).isVisible)
    }

    /// 撮影モード・テスト実行中・ID 無しでは、必要な地域でも出さない
    func testHiddenWhenAdsAreDisabled() {
        let disabled = [
            AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true),
            AdEligibility(isScreenshotDemo: false, isRunningTests: true, hasConfiguration: true),
            AdEligibility(isScreenshotDemo: false, isRunningTests: false, hasConfiguration: false)
        ]
        for eligibility in disabled {
            let model = PrivacyOptionsModel(eligibility: eligibility, presenter: FakePresenter(isPrivacyOptionsRequired: true))
            XCTAssertFalse(model.isVisible, "\(eligibility)")
        }
    }

    /// 起動時の同意情報の更新が済んだあとで設定画面を開くと、出すかを読み直す
    func testRefreshReadsCurrentRequirement() {
        let presenter = FakePresenter(isPrivacyOptionsRequired: false)
        let model = PrivacyOptionsModel(eligibility: enabled, presenter: presenter)

        presenter.isPrivacyOptionsRequired = true
        model.refresh()

        XCTAssertTrue(model.isVisible)
    }

    func testPresentShowsForm() async {
        let presenter = FakePresenter(isPrivacyOptionsRequired: true)
        let model = PrivacyOptionsModel(eligibility: enabled, presenter: presenter)

        await model.present()

        XCTAssertEqual(presenter.presentCount, 1)
    }

    func testPresentDoesNothingWhenHidden() async {
        let disabled = AdEligibility(isScreenshotDemo: true, isRunningTests: false, hasConfiguration: true)
        let presenter = FakePresenter(isPrivacyOptionsRequired: true)
        let model = PrivacyOptionsModel(eligibility: disabled, presenter: presenter)

        await model.present()

        XCTAssertEqual(presenter.presentCount, 0)
    }

    /// フォームが失敗しても落ちず、項目はそのまま
    func testPresentFailureKeepsItem() async {
        let presenter = FakePresenter(isPrivacyOptionsRequired: true, error: FormError())
        let model = PrivacyOptionsModel(eligibility: enabled, presenter: presenter)

        await model.present()

        XCTAssertTrue(model.isVisible)
    }

    func testPresentRefreshesAfterFormCloses() async {
        let presenter = FakePresenter(isPrivacyOptionsRequired: true)
        presenter.isRequiredAfterPresent = false
        let model = PrivacyOptionsModel(eligibility: enabled, presenter: presenter)

        await model.present()

        XCTAssertFalse(model.isVisible)
    }

    /// テストホストのアプリは、実際の UMP につないだものでも項目を出さない
    func testLiveModelIsHiddenWhileRunningTests() {
        XCTAssertFalse(PrivacyOptionsModel.live().isVisible)
    }
}
