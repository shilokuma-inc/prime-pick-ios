//
//  PrivacyPolicyViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class PrivacyPolicyViewTests: XCTestCase {

    /// 公開済みのページを指すこと。URL は App Store Connect の登録とも揃えるため変えない
    func testURLPointsToPublishedPrivacyPolicy() {
        XCTAssertEqual(
            PrivacyPolicyView.url?.absoluteString,
            "https://shilokuma-inc.github.io/iOS-Release-Sample/PrivacyPolicy/Prime-Pick/PrivacyPolicy.html"
        )
    }
}
