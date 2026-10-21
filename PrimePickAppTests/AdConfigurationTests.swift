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
            "AdMobNativeAdUnitIDQuizResult": "ca-app-pub-1/4"
        ])
        XCTAssertEqual(configuration?.applicationID, "ca-app-pub-1~2")
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .quizResult), "ca-app-pub-1/4")
    }

    /// App ID が欠けたら、広告ユニット ID があっても広告まわりを全部動かさない
    func testIsNilWhenApplicationIDIsMissingOrEmpty() {
        XCTAssertNil(AdConfiguration(infoDictionary: nil))
        XCTAssertNil(AdConfiguration(infoDictionary: ["AdMobNativeAdUnitIDQuizResult": "ca-app-pub-1/4"]))
        XCTAssertNil(AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "",
            "AdMobNativeAdUnitIDQuizResult": "ca-app-pub-1/4"
        ]))
    }

    /// AdMob の準備ができるまでは Google 公式のテスト用 ID を使う。本番 ID に差し替えたらこのテストも直す
    func testAppUsesGoogleTestIDs() {
        let configuration = AdConfiguration.current
        XCTAssertEqual(configuration?.applicationID, "ca-app-pub-3940256099942544~1458002511")
        for placement in AdPlacement.allCases {
            XCTAssertEqual(
                configuration?.nativeAdUnitID(for: placement), "ca-app-pub-3940256099942544/3986624511",
                "\(placement)"
            )
        }
    }

    /// Google Mobile Ads SDK は SKAdNetworkItems の一覧を前提にしている。Google の一覧の先頭（Google 自身）が入っていることを確かめる
    func testInfoPlistHasSKAdNetworkItems() throws {
        let items = try XCTUnwrap(Bundle.main.infoDictionary?["SKAdNetworkItems"] as? [[String: String]])
        let identifiers = items.compactMap { $0["SKAdNetworkIdentifier"] }
        XCTAssertTrue(identifiers.contains("cstr6suwn9.skadnetwork"))
        XCTAssertEqual(Set(identifiers).count, identifiers.count, "重複がある")
    }
}
