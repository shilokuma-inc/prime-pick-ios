//
//  DailyReminderAnalyticsEvent.swift
//  PrimePickApp
//

import Foundation

/// デイリーのリマインドの計測イベント
///
/// Firebase のパラメータ値は文字列か数値のみのため、オン／オフなどの真偽も文字列か数値で送る。
enum DailyReminderAnalyticsEvent: Equatable {
    /// どこからオン／オフを変えたか
    enum Source: String, Equatable {
        /// 設定画面のトグル
        case settings
        /// デイリーの結果画面の案内
        case dailyResult = "daily_result"
        /// 設定アプリで通知を止められていたため、オフに戻した
        case systemSettings = "system_settings"
    }

    /// 結果画面の案内で選んだボタン
    enum PromptAction: String, Equatable {
        case turnOn = "turn_on"
        case notNow = "not_now"
    }

    /// タップされた通知が、予約した日から見てどの日の分か
    enum NotificationKind: String, Equatable {
        /// 予約した日の分（決まった文面）
        case sameDay = "same_day"
        /// 翌日分（連続日数を入れた文面）
        case nextDay = "next_day"
        /// 2 日目以降の分（決まった文面）
        case later
        /// 予約した日から何日後かが読めなかった
        case unknown

        init(daysAhead: Int?) {
            switch daysAhead {
            case .none:
                self = .unknown
            case let .some(days) where days <= 0:
                self = .sameDay
            case 1:
                self = .nextDay
            default:
                self = .later
            }
        }
    }

    /// リマインドのオン／オフが変わった
    case toggle(isEnabled: Bool, source: Source)
    /// 通知の時刻を変えた
    case timeChange(hour: Int, minute: Int)
    /// OS の許可ダイアログの結果（ダイアログを出したときだけ）
    case permissionResult(granted: Bool, source: Source)
    /// 結果画面にリマインドの案内を出した
    case promptShow
    /// 結果画面の案内でボタンを選んだ
    case promptAction(PromptAction)
    /// リマインドの通知をタップした。`daysAhead` は予約した日から何日後の分か（読めなければ nil）
    case notificationTap(dayNumber: Int, daysAhead: Int?)

    /// タップされた通知から `notificationTap` を作る
    init(tap: DailyReminderTap) {
        self = .notificationTap(dayNumber: tap.day.dayNumber, daysAhead: tap.daysAhead)
    }

    var name: String {
        switch self {
        case .toggle:
            return "daily_reminder_toggle"
        case .timeChange:
            return "daily_reminder_time_change"
        case .permissionResult:
            return "daily_reminder_permission"
        case .promptShow:
            return "daily_reminder_prompt_show"
        case .promptAction:
            return "daily_reminder_prompt_action"
        case .notificationTap:
            return "daily_reminder_tap"
        }
    }

    /// Firebase Analytics に渡すパラメータ
    var parameters: [String: Any] {
        switch self {
        case let .toggle(isEnabled, source):
            return [
                "enabled": isEnabled ? 1 : 0,
                "source": source.rawValue
            ]
        case let .timeChange(hour, minute):
            return [
                "hour": hour,
                "minute": minute
            ]
        case let .permissionResult(granted, source):
            return [
                "result": granted ? "granted" : "denied",
                "source": source.rawValue
            ]
        case .promptShow:
            return [:]
        case let .promptAction(action):
            return [
                "action": action.rawValue
            ]
        case let .notificationTap(dayNumber, daysAhead):
            var parameters: [String: Any] = [
                "day_number": dayNumber,
                "notification_kind": NotificationKind(daysAhead: daysAhead).rawValue
            ]
            if let daysAhead {
                parameters["days_ahead"] = daysAhead
            }
            return parameters
        }
    }
}
