//
//  AppName.swift
//  PrimePickApp
//

import Foundation

/// アプリ名（ホーム画面に出る名前）
///
/// 名前は言語ごとに違い（Issue #524）、`InfoPlist.xcstrings` の `CFBundleDisplayName` にだけ書く。
/// シェアの文・画像カードなど、アプリの中でアプリ名を出すところはこれを使い、名前を文字列に直接書かない
enum AppName {
    /// Info.plist から名前を読めなかったときの名前（英語の名前。`INFOPLIST_KEY_CFBundleDisplayName` と同じ）
    static let fallback = "Prime or Not?"

    /// 表示している言語のアプリ名
    static var current: String {
        displayName(localizedInfoDictionary: Bundle.main.localizedInfoDictionary, infoDictionary: Bundle.main.infoDictionary)
    }

    /// 表示している言語の訳（`localizedInfoDictionary`）を優先し、無ければ Info.plist の値（英語の名前）を使う
    static func displayName(localizedInfoDictionary: [String: Any]?, infoDictionary: [String: Any]?) -> String {
        for dictionary in [localizedInfoDictionary, infoDictionary] {
            if let name = dictionary?["CFBundleDisplayName"] as? String, !name.isEmpty {
                return name
            }
        }
        return fallback
    }
}
