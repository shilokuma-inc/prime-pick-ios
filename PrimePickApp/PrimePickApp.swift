//
//  PrimePickApp.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

@main
struct PrimePickApp: App {
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
    }
}
