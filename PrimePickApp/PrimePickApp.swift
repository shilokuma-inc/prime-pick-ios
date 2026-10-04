//
//  PrimePickApp.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

@main
struct PrimePickApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            MainView()
                // 撮影モードでは端末やテーマ設定によらず同じ配色で撮る
                .preferredColorScheme(ScreenshotDemo.colorScheme ?? AppTheme(rawValue: appTheme)?.colorScheme)
        }
    }
}
