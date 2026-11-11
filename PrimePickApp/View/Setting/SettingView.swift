//
//  SettingView.swift
//  PrimePickApp
//

import SwiftUI

/// メイン画面右上の歯車から開く設定画面
struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue
    @StateObject private var privacyOptions = PrivacyOptionsModel.live()

    private let appVersion = AppVersion.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    themeSection
                    if privacyOptions.isVisible {
                        adsSection
                    }
                    appInfoSection

                    // 一覧のいちばん下に置く。読み込みを始める時点で枠を確保し、
                    // 読み込めなかったときは行ごと消す（高さも区切りも残らない）
                    AdNativeAdView(placement: .setting)
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
            }
            .sendAnalyticsScreen(.settings)
            .onAppear(perform: privacyOptions.refresh)
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

    /// 広告の同意をやり直す項目。UMP が必要とする地域（EU・英国など）の利用者にだけ出す
    var adsSection: some View {
        Section {
            Button("Privacy Settings") {
                Task { await privacyOptions.present() }
            }
        } header: {
            Text("Ads")
        } footer: {
            Text("You can change your consent to how ads use your data.")
        }
    }

    var appInfoSection: some View {
        Section {
            // ビルド番号の欄（日時と元の番号）は長いので、縮めずに 2 行目に出す
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("App Version")

                    Spacer()

                    Text(appVersion.versionText)
                        .foregroundStyle(.secondary)
                }

                if let detailLineText = appVersion.detailLineText {
                    Text(detailLineText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                }
            }
            .accessibilityElement(children: .combine)

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
