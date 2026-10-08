//
//  SettingView.swift
//  PrimePickApp
//

import SwiftUI

/// メイン画面右上の歯車から開く設定画面
struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeAttackRecordStore) private var timeAttackRecordStore
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue
    /// 記録のリセットの確認を出しているか
    @State private var isResetConfirmationPresented = false
    var bestScoreStore = BestScoreStore()

    private let appVersion = AppVersion.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    themeSection
                    recordSection
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

    /// タイムアタックの記録のリセット（Discussion #223 Q4）。確認ダイアログを挟んで、1 プレイの記録と自己ベストを消す
    var recordSection: some View {
        Section {
            Button("Reset Records", role: .destructive) {
                isResetConfirmationPresented = true
            }
            .confirmationDialog(
                "Reset all records?",
                isPresented: $isResetConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive, action: resetRecords)
            } message: {
                Text("Your play history and personal bests for every time limit and difficulty will be deleted. This cannot be undone.")
            }
        } header: {
            Text("Records")
        }
    }

    func resetRecords() {
        timeAttackRecordStore.deleteAll()
        bestScoreStore.deleteAll()
    }

    var appInfoSection: some View {
        Section {
            HStack {
                Text("App Version")

                Spacer()

                Text(appVersion.displayText)
                    .foregroundStyle(.secondary)
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Text("Privacy Policy")
            }

            NavigationLink {
                LicenseView()
            } label: {
                Text("Licenses")
            }
        } header: {
            Text("App Info")
        }
    }
}

#Preview {
    SettingView()
}
