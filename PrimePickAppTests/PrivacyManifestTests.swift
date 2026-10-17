//
//  PrivacyManifestTests.swift
//  PrimePickAppTests
//

import XCTest

final class PrivacyManifestTests: XCTestCase {

    private func manifest() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"), "アプリに PrivacyInfo.xcprivacy が入っていない")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    /// ATT で許可した人にパーソナライズ広告を出すので、トラッキングありと宣言する
    func testDeclaresTracking() throws {
        XCTAssertEqual(try manifest()["NSPrivacyTracking"] as? Bool, true)
    }

    /// 自己ベストなどをアプリ自身の UserDefaults に保存する（理由 CA92.1）
    func testDeclaresUserDefaultsReason() throws {
        let types = try XCTUnwrap(try manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = types.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" }
        XCTAssertEqual(userDefaults?["NSPrivacyAccessedAPITypeReasons"] as? [String], ["CA92.1"])
    }
}
