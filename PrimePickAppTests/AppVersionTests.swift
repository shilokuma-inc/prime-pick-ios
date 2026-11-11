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

    // MARK: - ビルド番号（yyyyMMdd.HHmmss、UTC）を日時に直す

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let japanese = Locale(identifier: "ja_JP")

    private func version(buildNumber: String?, shortVersion: String? = "1.2.0",
                         timeZone: TimeZone, locale: Locale) -> AppVersion {
        var info: [String: Any] = [:]
        if let shortVersion {
            info["CFBundleShortVersionString"] = shortVersion
        }
        if let buildNumber {
            info["CFBundleVersion"] = buildNumber
        }
        return AppVersion(infoDictionary: info, timeZone: timeZone, locale: locale)
    }

    func testBuildDateIsParsedAsUTC() throws {
        let date = try XCTUnwrap(version(buildNumber: "20261109.123456", timeZone: tokyo, locale: japanese).buildDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 9)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 34)
        XCTAssertEqual(components.second, 56)
    }

    func testBuildDateTextIsConvertedToTokyoTime() {
        let version = version(buildNumber: "20261109.123456", timeZone: tokyo, locale: japanese)
        XCTAssertEqual(version.buildDateText, "2026/11/09 21:34")
        XCTAssertEqual(version.buildDetailText, "2026/11/09 21:34 · 20261109.123456")
        XCTAssertEqual(version.displayText, "1.2.0 (2026/11/09 21:34 · 20261109.123456)")
    }

    func testBuildDateTextInUTCKeepsBuildNumberTime() {
        let version = version(buildNumber: "20261109.123456",
                              timeZone: TimeZone(identifier: "UTC")!, locale: japanese)
        XCTAssertEqual(version.buildDateText, "2026/11/09 12:34")
    }

    func testBuildDateTextCrossesDateBoundaryInTokyo() throws {
        // UTC の 18:30 は、日本では翌日の 3:30
        let version = version(buildNumber: "20261109.183000", timeZone: tokyo, locale: japanese)
        let date = try XCTUnwrap(version.buildDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tokyo
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 3)
        XCTAssertEqual(components.minute, 30)
        XCTAssertTrue(try XCTUnwrap(version.buildDateText).hasPrefix("2026/11/10 "))
    }

    func testBuildDateTextFollowsLocale() throws {
        let version = version(buildNumber: "20261109.123456", timeZone: tokyo,
                              locale: Locale(identifier: "en_US"))
        let text = try XCTUnwrap(version.buildDateText)
        XCTAssertTrue(text.contains("2026"), text)
        XCTAssertTrue(text.contains("9:34"), text)
        XCTAssertTrue(try XCTUnwrap(version.buildDetailText).hasSuffix(" · 20261109.123456"))
    }

    func testMalformedBuildNumberIsShownAsIs() {
        for buildNumber in ["1", "42", "20261109", "20261109123456", "20261109.12345", "20261109.1234567",
                            "2026110a.123456", " 20261109.123456", "20261109.123456 "] {
            let version = version(buildNumber: buildNumber, timeZone: tokyo, locale: japanese)
            XCTAssertNil(version.buildDate, buildNumber)
            XCTAssertNil(version.buildDateText, buildNumber)
            XCTAssertEqual(version.buildDetailText, buildNumber)
            XCTAssertEqual(version.displayText, "1.2.0 (\(buildNumber))")
        }
    }

    func testInvalidDateInBuildNumberIsShownAsIs() {
        for buildNumber in ["20261399.123456", "20261109.250000", "20260230.123456"] {
            let version = version(buildNumber: buildNumber, timeZone: tokyo, locale: japanese)
            XCTAssertNil(version.buildDate, buildNumber)
            XCTAssertEqual(version.displayText, "1.2.0 (\(buildNumber))")
        }
    }

    func testEmptyOrMissingBuildNumberHasNoDetail() {
        for buildNumber in [nil, ""] as [String?] {
            let version = version(buildNumber: buildNumber, timeZone: tokyo, locale: japanese)
            XCTAssertNil(version.buildDate)
            XCTAssertNil(version.buildDateText)
            XCTAssertNil(version.buildDetailText)
            XCTAssertEqual(version.displayText, "1.2.0")
        }
    }

    func testDisplayTextFallsBackWhenVersionIsMissingWithDateBuildNumber() {
        XCTAssertEqual(version(buildNumber: "20261109.123456", shortVersion: nil,
                               timeZone: tokyo, locale: japanese).displayText, "-")
        XCTAssertEqual(version(buildNumber: "20261109.123456", shortVersion: "",
                               timeZone: tokyo, locale: japanese).displayText, "-")
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
