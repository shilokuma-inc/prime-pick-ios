//
//  SettingView.swift
//  PrimePickApp
//

import SwiftUI

/// メイン画面右上の歯車から開く設定画面
struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue

    private let appVersion = AppVersion.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    themeSection
                    appInfoSection
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            .sendAnalyticsScreen(.settings)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension SettingView {
    var themeSection: some View {
        Section {
            Picker("Theme", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.localizedTitle)
                        .tag(theme.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("App Theme")
        } header: {
            Text("Theme")
        }
    }

    var appInfoSection: some View {
        Section {
            HStack {
                Text("App Version")

                Spacer()

                Text(appVersion.displayText)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("App Info")
        }
    }
}

#Preview {
    SettingView()
}
