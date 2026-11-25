//
//  SettingView.swift
//  PrimePickApp
//

import SwiftUI

/// メイン画面右上の歯車から開く設定画面
struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue
    @AppStorage(FeedbackSettings.isSoundEnabledKey) private var isSoundEnabled = true
    @AppStorage(FeedbackSettings.isHapticsEnabledKey) private var isHapticsEnabled = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @StateObject private var privacyOptions = PrivacyOptionsModel.live()
    @StateObject private var reminder = DailyReminderSettingsModel()

    private let appVersion = AppVersion.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                List {
                    themeSection
                    feedbackSection
                    reminderSection
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
            // 許可は設定アプリで変えられるので、開いたとき・前面に戻ったときに読み直す
            .task { await reminder.refresh() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await reminder.refresh() }
            }
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

    /// 効果音と振動のオン／オフ（#546）。鳴らす・振動させる直前に `FeedbackSettings` が同じキーを読む
    var feedbackSection: some View {
        Section {
            Toggle("Sound Effects", isOn: $isSoundEnabled)

            Toggle("Vibration", isOn: $isHapticsEnabled)
        } header: {
            Text("Sound & Vibration")
        } footer: {
            Text("Sound effects don't play in Silent Mode.")
        }
    }

    /// デイリーのリマインドのオン／オフと時刻。時刻はオンのときだけ出す
    var reminderSection: some View {
        Section {
            Toggle(
                "Daily Challenge Reminder",
                isOn: Binding(
                    get: { reminder.isEnabled },
                    set: { isOn in Task { await reminder.setEnabled(isOn) } }
                )
            )
            .disabled(reminder.isRequestingAuthorization)

            if reminder.isEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: { reminder.time.date() },
                        set: { date in Task { await reminder.setTime(DailyReminderTime(date: date)) } }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            if reminder.isAuthorizationDenied {
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
            }
        } header: {
            Text("Reminder")
        } footer: {
            if reminder.isAuthorizationDenied {
                Text("Notifications are turned off for this app. To get reminders, allow notifications in the Settings app.")
            } else {
                Text("We'll remind you on days you haven't played the Daily Challenge yet.")
            }
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

                    Text(appVersion.firstLineText)
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
