//
//  AppThemeTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class AppThemeTests: XCTestCase {

    /// 設定画面の Picker は rawValue を `@AppStorage` に保存するため、保存値から元のテーマに戻せることを確かめる
    func testRawValueRoundTrip() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(AppTheme(rawValue: theme.rawValue), theme)
        }
    }

    /// 既に保存済みの値と互換を保つため、保存される文字列を固定する
    func testRawValuesAreStable() {
        XCTAssertEqual(AppTheme.allCases.map(\.rawValue), ["system", "light", "dark"])
        XCTAssertEqual(AppTheme.userDefaultsKey, "appTheme")
    }

    func testColorScheme() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }

    func testUserInterfaceStyle() {
        XCTAssertEqual(AppTheme.system.userInterfaceStyle, .unspecified)
        XCTAssertEqual(AppTheme.light.userInterfaceStyle, .light)
        XCTAssertEqual(AppTheme.dark.userInterfaceStyle, .dark)
    }

    /// 撮影モードでは保存されたテーマによらずライトで撮る
    func testResolvedUserInterfaceStylePrefersScreenshotColorScheme() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(
                AppTheme.resolvedUserInterfaceStyle(rawValue: theme.rawValue, screenshotColorScheme: .light),
                .light
            )
        }
    }

    func testResolvedUserInterfaceStyleFollowsTheme() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(
                AppTheme.resolvedUserInterfaceStyle(rawValue: theme.rawValue, screenshotColorScheme: nil),
                theme.userInterfaceStyle
            )
        }
    }

    /// 想定外の保存値は端末設定に従う
    func testResolvedUserInterfaceStyleFallsBackToSystem() {
        XCTAssertEqual(
            AppTheme.resolvedUserInterfaceStyle(rawValue: "unknown", screenshotColorScheme: nil),
            .unspecified
        )
    }
}
