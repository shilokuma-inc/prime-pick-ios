//
//  AppNameTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AppNameTests: XCTestCase {

    func testPrefersLocalizedName() {
        let name = AppName.displayName(
            localizedInfoDictionary: ["CFBundleDisplayName": "素数どっち？"],
            infoDictionary: ["CFBundleDisplayName": "Prime or Not?"]
        )
        XCTAssertEqual(name, "素数どっち？")
    }

    func testFallsBackToInfoPlistName() {
        XCTAssertEqual(
            AppName.displayName(localizedInfoDictionary: [:], infoDictionary: ["CFBundleDisplayName": "Prime or Not?"]),
            "Prime or Not?"
        )
        XCTAssertEqual(
            AppName.displayName(localizedInfoDictionary: ["CFBundleDisplayName": ""], infoDictionary: ["CFBundleDisplayName": "Prime or Not?"]),
            "Prime or Not?"
        )
    }

    func testFallsBackToDefaultName() {
        XCTAssertEqual(AppName.displayName(localizedInfoDictionary: nil, infoDictionary: nil), AppName.fallback)
    }

    /// アプリの Info.plist から、表示している言語の名前を読める
    func testCurrentNameIsReadFromBundle() {
        let localized = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String
        let base = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        XCTAssertEqual(AppName.current, localized ?? base)
        XCTAssertFalse(AppName.current.isEmpty)
    }
}
