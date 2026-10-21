//
//  AdConfiguration.swift
//  PrimePickApp
//

import Foundation

/// AdMob の ID。値は `Info.plist` の 1 か所にまとめ、本番 ID への差し替えをそこだけで済ませる
///
/// いまは Google 公式のテスト用 ID を入れている（AdMob の準備ができたら本番 ID に差し替える）。
/// App ID（`GADApplicationIdentifier`）は Google Mobile Ads SDK が起動時に `Info.plist` から読む。
/// 広告ユニットは置き場所（`AdPlacement`）ごとに分け、AdMob のレポートで置き場所ごとの成果を見られるようにする
struct AdConfiguration: Equatable {
    static let applicationIDKey = "GADApplicationIdentifier"

    /// 置き場所ごとの広告ユニット ID を入れる `Info.plist` のキー。置き場所を足したら、ここと `Info.plist` に足す
    static func nativeAdUnitIDKey(for placement: AdPlacement) -> String {
        switch placement {
        case .quizResult: "AdMobNativeAdUnitIDQuizResult"
        case .dailyChallengeResult: "AdMobNativeAdUnitIDDailyChallengeResult"
        case .timeAttackRecords: "AdMobNativeAdUnitIDTimeAttackRecords"
        case .setting: "AdMobNativeAdUnitIDSetting"
        }
    }

    /// AdMob の App ID（`ca-app-pub-…~…`）
    let applicationID: String
    /// 置き場所ごとのネイティブ広告の広告ユニット ID（`ca-app-pub-…/…`）。ID が欠けている・空の置き場所は入れない
    let nativeAdUnitIDs: [AdPlacement: String]

    /// App ID が欠けている・空のときは nil。広告まわりを全部動かさない判断に使う
    init?(infoDictionary: [String: Any]?) {
        guard let applicationID = infoDictionary?[Self.applicationIDKey] as? String,
              !applicationID.isEmpty else {
            return nil
        }
        self.applicationID = applicationID
        var nativeAdUnitIDs: [AdPlacement: String] = [:]
        for placement in AdPlacement.allCases {
            if let adUnitID = infoDictionary?[Self.nativeAdUnitIDKey(for: placement)] as? String, !adUnitID.isEmpty {
                nativeAdUnitIDs[placement] = adUnitID
            }
        }
        self.nativeAdUnitIDs = nativeAdUnitIDs
    }

    /// その置き場所の広告ユニット ID。欠けている・空のときは nil で、その置き場所にだけ広告を出さない
    func nativeAdUnitID(for placement: AdPlacement) -> String? {
        nativeAdUnitIDs[placement]
    }

    static let current = AdConfiguration(infoDictionary: Bundle.main.infoDictionary)
}
