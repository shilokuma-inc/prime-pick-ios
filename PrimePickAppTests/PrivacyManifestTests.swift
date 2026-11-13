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

    /// アプリのコード自身はトラッキングしない（IDFA は Google Mobile Ads が扱い、SDK 側のマニフェストが宣言する）。
    /// true にするならトラッキングのドメインを 1 つ以上並べないと App Store Connect で ITMS-91064 になる（#508）
    func testDoesNotDeclareTrackingForAppCode() throws {
        let manifest = try manifest()
        XCTAssertEqual(manifest["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual(manifest["NSPrivacyTrackingDomains"] as? [String], [])
    }

    /// 自己ベストなどをアプリ自身の UserDefaults に保存する（理由 CA92.1）
    func testDeclaresUserDefaultsReason() throws {
        let types = try XCTUnwrap(try manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let userDefaults = types.first { $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults" }
        XCTAssertEqual(userDefaults?["NSPrivacyAccessedAPITypeReasons"] as? [String], ["CA92.1"])
    }
}
