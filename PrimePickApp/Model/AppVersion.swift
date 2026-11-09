//
//  AppVersion.swift
//  PrimePickApp
//

import Foundation

/// 設定画面に表示するアプリのバージョン
struct AppVersion {
    /// `CFBundleShortVersionString`（例: 1.2.0）
    let shortVersion: String?
    /// `CFBundleVersion`（例: 202611091230）
    let buildNumber: String?

    init(infoDictionary: [String: Any]?) {
        shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        buildNumber = infoDictionary?["CFBundleVersion"] as? String
    }

    static let current = AppVersion(infoDictionary: Bundle.main.infoDictionary)

    /// 画面に出す文字列（例: 1.2.0 (42)）。ビルド番号が取得できない場合はバージョンだけを、
    /// バージョンが取得できない場合は「-」を返す
    var displayText: String {
        guard let shortVersion, !shortVersion.isEmpty else {
            return "-"
        }
        guard let buildNumber, !buildNumber.isEmpty else {
            return shortVersion
        }
        return "\(shortVersion) (\(buildNumber))"
    }
}
