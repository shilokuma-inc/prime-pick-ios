//
//  AppVersionTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AppVersionTests: XCTestCase {

    func testDisplayTextIsShortVersion() {
        let version = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "1.2.0",
            "CFBundleVersion": "42"
        ])
        XCTAssertEqual(version.displayText, "1.2.0")
    }

    func testDisplayTextFallsBackWhenVersionIsMissing() {
        XCTAssertEqual(AppVersion(infoDictionary: [:]).displayText, "-")
        XCTAssertEqual(AppVersion(infoDictionary: nil).displayText, "-")
    }

    func testDisplayTextFallsBackWhenVersionIsEmpty() {
        let version = AppVersion(infoDictionary: ["CFBundleShortVersionString": ""])
        XCTAssertEqual(version.displayText, "-")
    }

    func testCurrentReadsMainBundleVersion() {
        let expected = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        XCTAssertEqual(AppVersion.current.shortVersion, expected)
    }
}
