//
//  AdConfigurationTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AdConfigurationTests: XCTestCase {

    func testReadsIDsFromInfoDictionary() {
        let configuration = AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "ca-app-pub-1~2",
            "AdMobNativeAdUnitID": "ca-app-pub-1/4"
        ])
        XCTAssertEqual(configuration?.applicationID, "ca-app-pub-1~2")
        XCTAssertEqual(configuration?.nativeAdUnitID, "ca-app-pub-1/4")
    }

    func testIsNilWhenIDIsMissingOrEmpty() {
        XCTAssertNil(AdConfiguration(infoDictionary: nil))
        XCTAssertNil(AdConfiguration(infoDictionary: ["GADApplicationIdentifier": "ca-app-pub-1~2"]))
        XCTAssertNil(AdConfiguration(infoDictionary: ["AdMobNativeAdUnitID": "ca-app-pub-1/4"]))
        XCTAssertNil(AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "",
            "AdMobNativeAdUnitID": "ca-app-pub-1/4"
        ]))
        XCTAssertNil(AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "ca-app-pub-1~2",
            "AdMobNativeAdUnitID": ""
        ]))
    }

    /// AdMob の準備ができるまでは Google 公式のテスト用 ID を使う。本番 ID に差し替えたらこのテストも直す
    func testAppUsesGoogleTestIDs() {
        let configuration = AdConfiguration.current
        XCTAssertEqual(configuration?.applicationID, "ca-app-pub-3940256099942544~1458002511")
        XCTAssertEqual(configuration?.nativeAdUnitID, "ca-app-pub-3940256099942544/3986624511")
    }

    /// Google Mobile Ads SDK は SKAdNetworkItems の一覧を前提にしている。Google の一覧の先頭（Google 自身）が入っていることを確かめる
    func testInfoPlistHasSKAdNetworkItems() throws {
        let items = try XCTUnwrap(Bundle.main.infoDictionary?["SKAdNetworkItems"] as? [[String: String]])
        let identifiers = items.compactMap { $0["SKAdNetworkIdentifier"] }
        XCTAssertTrue(identifiers.contains("cstr6suwn9.skadnetwork"))
        XCTAssertEqual(Set(identifiers).count, identifiers.count, "重複がある")
    }
}
