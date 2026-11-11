//
//  AppVersion.swift
//  PrimePickApp
//

import Foundation

/// 設定画面に表示するアプリのバージョン
struct AppVersion {
    /// `CFBundleShortVersionString`（例: 1.2.0）
    let shortVersion: String?
    /// `CFBundleVersion`（例: 20261109.123456。`upload.yml` が UTC の日時で付ける。手元のビルドでは 1 など）
    let buildNumber: String?
    /// ビルドの日時を表示するタイムゾーン
    let timeZone: TimeZone
    /// ビルドの日時を表示する言語・地域
    let locale: Locale

    init(infoDictionary: [String: Any]?, timeZone: TimeZone = .current, locale: Locale = .current) {
        shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        buildNumber = infoDictionary?["CFBundleVersion"] as? String
        self.timeZone = timeZone
        self.locale = locale
    }

    /// 端末のタイムゾーンと言語で表示するよう、参照するたびに作る
    static var current: AppVersion {
        AppVersion(infoDictionary: Bundle.main.infoDictionary)
    }

    /// ビルド番号を yyyyMMdd.HHmmss（UTC）として読んだ日時。形が合わない場合は nil
    var buildDate: Date? {
        guard let buildNumber,
              buildNumber.wholeMatch(of: #/[0-9]{8}\.[0-9]{6}/#) != nil else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd.HHmmss"
        formatter.isLenient = false
        return formatter.date(from: buildNumber)
    }

    /// ビルドの日時を `timeZone` と `locale` に合わせて整えた文字列（例: ja の日本の端末で 2026/11/09 21:34）。
    /// ビルド番号の形が合わない場合は nil
    var buildDateText: String? {
        guard let buildDate else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMddjjmm")
        return formatter.string(from: buildDate)
    }

    /// ビルド番号の欄の文字列（例: 2026/11/09 21:34 · 20261109.123456）。
    /// 日時に直せない場合は元のビルド番号だけを、ビルド番号が取得できない場合は nil を返す
    var buildDetailText: String? {
        guard let buildNumber, !buildNumber.isEmpty else {
            return nil
        }
        guard let buildDateText else {
            return buildNumber
        }
        return "\(buildDateText) · \(buildNumber)"
    }

    /// 画面に出す文字列（例: 1.2.0 (2026/11/09 21:34 · 20261109.123456)、形が合わないビルド番号では 1.2.0 (42)）。
    /// ビルド番号が取得できない場合はバージョンだけを、バージョンが取得できない場合は「-」を返す
    var displayText: String {
        guard let shortVersion, !shortVersion.isEmpty else {
            return "-"
        }
        guard let buildDetailText else {
            return shortVersion
        }
        return "\(shortVersion) (\(buildDetailText))"
    }
}
