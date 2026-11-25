//
//  FeedbackSettings.swift
//  PrimePickApp
//

import Foundation

/// 効果音と振動のオン／オフ（#546）
///
/// 設定画面のトグルが `@AppStorage` で同じキーに書く。鳴らす・振動させる直前に毎回読むので、切り替えはすぐ効く。
/// どちらも既定はオン（設定を足す前と同じ動き）。マナーモードで効果音が鳴らないのは、この設定によらず今のまま。
struct FeedbackSettings {
    /// 効果音を鳴らすか（`SoundFeedback.play` で鳴らすものすべて）
    static let isSoundEnabledKey = "feedback.isSoundEnabled"
    /// 振動させるか（解答・ボタンの押下・モード選択の `sensoryFeedback` すべて）
    static let isHapticsEnabledKey = "feedback.isHapticsEnabled"

    /// アプリが使う設定（`UserDefaults.standard`）
    static var current: FeedbackSettings { FeedbackSettings() }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isSoundEnabled: Bool {
        userDefaults.object(forKey: Self.isSoundEnabledKey) as? Bool ?? true
    }

    var isHapticsEnabled: Bool {
        userDefaults.object(forKey: Self.isHapticsEnabledKey) as? Bool ?? true
    }
}
