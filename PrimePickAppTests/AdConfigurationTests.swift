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

    func testReadsAdUnitIDForEachPlacement() {
        let configuration = AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "ca-app-pub-1~2",
            "AdMobNativeAdUnitIDQuizResult": "ca-app-pub-1/1",
            "AdMobNativeAdUnitIDDailyChallengeResult": "ca-app-pub-1/2",
            "AdMobNativeAdUnitIDTimeAttackRecords": "ca-app-pub-1/3",
            "AdMobNativeAdUnitIDSetting": "ca-app-pub-1/4"
        ])
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .quizResult), "ca-app-pub-1/1")
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .dailyChallengeResult), "ca-app-pub-1/2")
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .timeAttackRecords), "ca-app-pub-1/3")
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .setting), "ca-app-pub-1/4")
    }

    /// 広告ユニット ID が欠けている・空の置き場所だけ nil にして、ほかの置き場所には出す
    func testAdUnitIDIsNilOnlyForMissingOrEmptyPlacement() {
        let configuration = AdConfiguration(infoDictionary: [
            "GADApplicationIdentifier": "ca-app-pub-1~2",
            "AdMobNativeAdUnitIDQuizResult": "ca-app-pub-1/1",
            "AdMobNativeAdUnitIDDailyChallengeResult": "",
            "AdMobNativeAdUnitIDSetting": "ca-app-pub-1/4"
        ])
        XCTAssertNotNil(configuration, "App ID があれば、広告ユニット ID が欠けていても nil にしない")
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .quizResult), "ca-app-pub-1/1")
        XCTAssertNil(configuration?.nativeAdUnitID(for: .dailyChallengeResult))
        XCTAssertNil(configuration?.nativeAdUnitID(for: .timeAttackRecords))
        XCTAssertEqual(configuration?.nativeAdUnitID(for: .setting), "ca-app-pub-1/4")
    }

    /// 置き場所ごとのキーが重ならない（取り違えると 2 か所が同じ広告ユニットになる）
    func testAdUnitIDKeysAreDistinct() {
        let keys = AdPlacement.allCases.map(AdConfiguration.nativeAdUnitIDKey(for:))
        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertFalse(keys.contains(AdConfiguration.applicationIDKey))
    }

    /// 置き場所を足したのに Info.plist に ID を足し忘れると、その置き場所だけ黙って広告が出なくなる。足し忘れをここで気づく
    func testInfoPlistHasAdUnitIDForEveryPlacement() {
        let configuration = AdConfiguration.current
        XCTAssertNotNil(configuration)
        for placement in AdPlacement.allCases {
            XCTAssertNotNil(
                configuration?.nativeAdUnitID(for: placement),
                "Info.plist に \(AdConfiguration.nativeAdUnitIDKey(for: placement)) が無い"
            )
        }
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
