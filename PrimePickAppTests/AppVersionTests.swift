//
//  AppVersionTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AppVersionTests: XCTestCase {

    func testDisplayTextIsShortVersionWithBuildNumber() {
        let version = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "1.2.0",
            "CFBundleVersion": "42"
        ])
        XCTAssertEqual(version.displayText, "1.2.0 (42)")
    }

    func testDisplayTextIsShortVersionWhenBuildNumberIsMissing() {
        let version = AppVersion(infoDictionary: ["CFBundleShortVersionString": "1.2.0"])
        XCTAssertEqual(version.displayText, "1.2.0")
    }

    func testDisplayTextIsShortVersionWhenBuildNumberIsEmpty() {
        let version = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "1.2.0",
            "CFBundleVersion": ""
        ])
        XCTAssertEqual(version.displayText, "1.2.0")
    }

    func testDisplayTextFallsBackWhenVersionIsMissing() {
        XCTAssertEqual(AppVersion(infoDictionary: [:]).displayText, "-")
        XCTAssertEqual(AppVersion(infoDictionary: nil).displayText, "-")
        XCTAssertEqual(AppVersion(infoDictionary: ["CFBundleVersion": "42"]).displayText, "-")
    }

    func testDisplayTextFallsBackWhenVersionIsEmpty() {
        let version = AppVersion(infoDictionary: ["CFBundleShortVersionString": ""])
        XCTAssertEqual(version.displayText, "-")
        let versionWithBuild = AppVersion(infoDictionary: [
            "CFBundleShortVersionString": "",
            "CFBundleVersion": "42"
        ])
        XCTAssertEqual(versionWithBuild.displayText, "-")
    }

    func testCurrentReadsMainBundleVersion() {
        let expected = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        XCTAssertEqual(AppVersion.current.shortVersion, expected)
    }

    func testCurrentReadsMainBundleBuildNumber() {
        let expected = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        XCTAssertEqual(AppVersion.current.buildNumber, expected)
    }
}
