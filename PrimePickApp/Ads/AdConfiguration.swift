//
//  AdConfiguration.swift
//  PrimePickApp
//

import Foundation

/// AdMob の ID。値は `Info.plist` の 1 か所にまとめ、本番 ID への差し替えをそこだけで済ませる
///
/// いまは Google 公式のテスト用 ID を入れている（AdMob の準備ができたら本番 ID に差し替える）。
/// App ID（`GADApplicationIdentifier`）は Google Mobile Ads SDK が起動時に `Info.plist` から読む
struct AdConfiguration: Equatable {
    static let applicationIDKey = "GADApplicationIdentifier"
    static let nativeAdUnitIDKey = "AdMobNativeAdUnitID"

    /// AdMob の App ID（`ca-app-pub-…~…`）
    let applicationID: String
    /// ネイティブ広告の広告ユニット ID（`ca-app-pub-…/…`）
    let nativeAdUnitID: String

    /// ID が欠けている・空のときは nil。広告を出さない判断に使う
    init?(infoDictionary: [String: Any]?) {
        guard let applicationID = infoDictionary?[Self.applicationIDKey] as? String,
              let nativeAdUnitID = infoDictionary?[Self.nativeAdUnitIDKey] as? String,
              !applicationID.isEmpty,
              !nativeAdUnitID.isEmpty else {
            return nil
        }
        self.applicationID = applicationID
        self.nativeAdUnitID = nativeAdUnitID
    }

    static let current = AdConfiguration(infoDictionary: Bundle.main.infoDictionary)
}
