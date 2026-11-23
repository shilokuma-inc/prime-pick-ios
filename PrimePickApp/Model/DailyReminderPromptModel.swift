//
//  DailyReminderPromptModel.swift
//  PrimePickApp
//

import Foundation

/// デイリーの結果画面に出すリマインドの案内
///
/// 解き終えた直後で、リマインドがオフ・まだ案内していない・撮影モードでないときだけ出す。
/// 出した時点で案内済みにするので、選ばずに画面を閉じても次からは出さない（「オンにする」「今はしない」のどちらを選んでも案内済み）。
/// 「オンにする」は設定画面のトグルと同じ流れ（`DailyReminderSettingsModel.setEnabled`）で許可を求め、許可されたらオンにして予約する。
@MainActor
final class DailyReminderPromptModel: ObservableObject {
    enum State: Equatable {
        /// 案内を出さない（「今はしない」を選んだ後も含む）
        case hidden
        /// 「オンにする」「今はしない」を選んでもらう
        case asking
        /// 許可を求めている最中
        case requesting
        /// オンにした。届く時刻を伝える
        case enabled(DailyReminderTime)
        /// 許可されなかった。設定画面から変えられることを伝える
        case denied
    }

    @Published private(set) var state: State

    private let settingsStore: DailyReminderSettingsStore
    private let settingsModel: DailyReminderSettingsModel

    init(
        isJustFinished: Bool,
        settingsStore: DailyReminderSettingsStore = DailyReminderSettingsStore(),
        scheduler: DailyReminderScheduler = .shared,
        authorizer: any DailyReminderAuthorizing = SystemDailyReminderAuthorizer(),
        isScreenshotDemo: Bool = ScreenshotDemo.isEnabled
    ) {
        self.settingsStore = settingsStore
        settingsModel = DailyReminderSettingsModel(settingsStore: settingsStore, scheduler: scheduler, authorizer: authorizer)
        let shows = Self.shouldShow(
            isJustFinished: isJustFinished,
            settings: settingsStore.load(),
            isScreenshotDemo: isScreenshotDemo
        )
        state = shows ? .asking : .hidden
    }

    /// オンにしたときに届く時刻（設定値。初期は 20:00）
    var time: DailyReminderTime {
        settingsModel.time
    }

    /// 案内を出すか
    static func shouldShow(isJustFinished: Bool, settings: DailyReminderSettings, isScreenshotDemo: Bool) -> Bool {
        isJustFinished && !settings.isEnabled && !settings.hasShownResultPrompt && !isScreenshotDemo
    }

    /// 案内が画面に出たとき。案内済みとして記録する
    func didAppear() {
        guard state == .asking else { return }
        recordShown()
    }

    /// 「オンにする」を押したとき
    func enable() async {
        guard state == .asking else { return }
        recordShown()
        state = .requesting
        await settingsModel.setEnabled(true)
        state = settingsModel.isEnabled ? .enabled(settingsModel.time) : .denied
    }

    /// 「今はしない」を押したとき
    func decline() {
        guard state == .asking else { return }
        recordShown()
        state = .hidden
    }

    private func recordShown() {
        settingsStore.update { $0.hasShownResultPrompt = true }
    }
}
