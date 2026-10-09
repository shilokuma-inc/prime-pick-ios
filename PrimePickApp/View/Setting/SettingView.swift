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
    /// 記録のリセットに失敗したことを知らせているか
    @State private var isResetFailureAlertPresented = false
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
            .alert("Couldn't reset records", isPresented: $isResetFailureAlertPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Nothing was deleted. Please try again.")
            }
        } header: {
            Text("Records")
        }
    }

    func resetRecords() {
        do {
            try Self.resetRecords(recordStore: timeAttackRecordStore, bestScoreStore: bestScoreStore)
        } catch {
            isResetFailureAlertPresented = true
        }
    }
}

extension SettingView {
    /// 1 プレイの記録を消せたときだけ自己ベストも消す。記録が残ったまま自己ベストだけ消えると、記録画面とリザルトが食い違うため
    static func resetRecords(recordStore: any TimeAttackRecordStore, bestScoreStore: BestScoreStore) throws {
        try recordStore.deleteAll()
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
