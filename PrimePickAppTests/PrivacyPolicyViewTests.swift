//
//  PrivacyPolicyViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class PrivacyPolicyViewTests: XCTestCase {

    /// 公開済みのページ（Discussion #475 で差し替えた https://shilokuma.jp/privacy/prime-pick/）を指すこと。
    /// App Store Connect の「プライバシーポリシー URL」は担当者が手で同じページに揃える。URL を変えるときは、そちらも合わせて書き換える
    func testURLPointsToPublishedPrivacyPolicy() {
        XCTAssertEqual(
            PrivacyPolicyView.url?.absoluteString,
            "https://shilokuma.jp/privacy/prime-pick/"
        )
    }
}
