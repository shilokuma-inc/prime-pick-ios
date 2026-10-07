//
//  AppTheme.swift
//  PrimePickApp
//

import SwiftUI

/// アプリ全体へ適用する配色テーマの設定
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let userDefaultsKey = "appTheme"

    var id: String { rawValue }

    /// `.preferredColorScheme` に渡す値。`system` は端末設定に従うため nil を返す
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// ウィンドウの `overrideUserInterfaceStyle` に設定する値。`system` は端末設定に従うため `.unspecified` を返す
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    /// ウィンドウへ実際に適用する値。撮影モードの固定配色（`screenshotColorScheme`）があればテーマ設定より優先する
    static func resolvedUserInterfaceStyle(
        rawValue: String,
        screenshotColorScheme: ColorScheme?
    ) -> UIUserInterfaceStyle {
        if let screenshotColorScheme {
            return UIUserInterfaceStyle(screenshotColorScheme)
        }
        return (AppTheme(rawValue: rawValue) ?? .system).userInterfaceStyle
    }

    var localizedTitle: LocalizedStringKey {
        switch self {
        case .system:
            return "端末設定に従う"
        case .light:
            return "ライト"
        case .dark:
            return "ダーク"
        }
    }
}
