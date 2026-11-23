//
//  DailyReminderSettings.swift
//  PrimePickApp
//

import Foundation
import QuizCore

/// デイリーのリマインドを届ける時刻（時・分。端末のタイムゾーンで数える）
struct DailyReminderTime: Equatable {
    /// 初期値の 20:00
    static let defaultTime = DailyReminderTime(validHour: 20, minute: 0)

    let hour: Int
    let minute: Int

    private init(validHour hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    /// 範囲外（0〜23 時・0〜59 分の外）の値では nil
    init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }
}

/// デイリーのリマインドの設定
///
/// 初めて起動した状態ではオフで、許可も求めていない。オンにすると毎日 `time` に届く。
struct DailyReminderSettings: Equatable {
    /// リマインドを届けるか。初期値はオフ
    var isEnabled = false
    /// 届ける時刻。初期値は 20:00
    var time = DailyReminderTime.defaultTime
    /// デイリーの結果画面でリマインドの案内を出したか（「オンにする」「今はしない」のどちらを選んでも出し済み）
    var hasShownResultPrompt = false
    /// OS の通知の許可ダイアログを出したか
    var hasRequestedAuthorization = false
    /// 最後にアプリを開いた（前面に戻った）日。予約はこの日から `DailyReminderPlanner.scheduleDays` 日先までに限る
    var lastOpenedDay: DailyChallengeDay?
}

/// `DailyReminderSettings` を UserDefaults に保存する
///
/// 項目ごとに別のキーにする（設定画面から `@AppStorage` でも読めるようにするため）。テストでは使い捨ての領域を注入する。
struct DailyReminderSettingsStore {
    static let isEnabledKey = "dailyReminder.isEnabled"
    static let hourKey = "dailyReminder.hour"
    static let minuteKey = "dailyReminder.minute"
    static let hasShownResultPromptKey = "dailyReminder.hasShownResultPrompt"
    static let hasRequestedAuthorizationKey = "dailyReminder.hasRequestedAuthorization"
    /// 最後に開いた日（`DailyChallengeDay.dayKey` の形式）
    static let lastOpenedDayKey = "dailyReminder.lastOpenedDay"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// 保存された設定。保存されていない項目は初期値にし、時刻が読めなければ 20:00 にする
    func load() -> DailyReminderSettings {
        var settings = DailyReminderSettings()
        settings.isEnabled = userDefaults.bool(forKey: Self.isEnabledKey)
        if let hour = userDefaults.object(forKey: Self.hourKey) as? Int,
           let minute = userDefaults.object(forKey: Self.minuteKey) as? Int,
           let time = DailyReminderTime(hour: hour, minute: minute) {
            settings.time = time
        }
        settings.hasShownResultPrompt = userDefaults.bool(forKey: Self.hasShownResultPromptKey)
        settings.hasRequestedAuthorization = userDefaults.bool(forKey: Self.hasRequestedAuthorizationKey)
        settings.lastOpenedDay = userDefaults.string(forKey: Self.lastOpenedDayKey).flatMap(DailyChallengeDay.init(dayKey:))
        return settings
    }

    func save(_ settings: DailyReminderSettings) {
        userDefaults.set(settings.isEnabled, forKey: Self.isEnabledKey)
        userDefaults.set(settings.time.hour, forKey: Self.hourKey)
        userDefaults.set(settings.time.minute, forKey: Self.minuteKey)
        userDefaults.set(settings.hasShownResultPrompt, forKey: Self.hasShownResultPromptKey)
        userDefaults.set(settings.hasRequestedAuthorization, forKey: Self.hasRequestedAuthorizationKey)
        if let lastOpenedDay = settings.lastOpenedDay {
            userDefaults.set(lastOpenedDay.dayKey, forKey: Self.lastOpenedDayKey)
        } else {
            userDefaults.removeObject(forKey: Self.lastOpenedDayKey)
        }
    }

    /// 読んで書き換えて保存する
    func update(_ change: (inout DailyReminderSettings) -> Void) {
        var settings = load()
        change(&settings)
        save(settings)
    }
}
