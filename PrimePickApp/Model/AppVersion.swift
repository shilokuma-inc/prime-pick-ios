//
//  AppVersion.swift
//  PrimePickApp
//

import Foundation

/// 設定画面に表示するアプリのバージョン
struct AppVersion {
    /// `CFBundleShortVersionString`（例: 1.2.0）
    let shortVersion: String?

    init(infoDictionary: [String: Any]?) {
        shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static let current = AppVersion(infoDictionary: Bundle.main.infoDictionary)

    /// 画面に出す文字列。取得できない場合は「-」を返す
    var displayText: String {
        guard let shortVersion, !shortVersion.isEmpty else {
            return "-"
        }
        return shortVersion
    }
}
