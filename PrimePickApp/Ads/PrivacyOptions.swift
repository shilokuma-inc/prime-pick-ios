//
//  PrivacyOptions.swift
//  PrimePickApp
//

import Foundation

/// UMP のプライバシー オプション（同意のやり直し）のフォーム。SDK に依存する部分を包み、出す・出さないの判定を SDK 無しでテストできるようにする
@MainActor
protocol PrivacyOptionsPresenting: AnyObject {
    /// 同意の変更手段を用意しなければならない利用者か（EU・英国など。UMP の `privacyOptionsRequirementStatus`）
    var isPrivacyOptionsRequired: Bool { get }
    /// プライバシー オプションのフォームを出す。閉じるまで待つ
    func presentPrivacyOptions() async throws
}

/// 設定画面の「プライバシー設定」の項目
///
/// UMP が必要とする利用者にだけ出す。撮影モード・テスト実行中は出さない（同意フォームも動かさない）
@MainActor
final class PrivacyOptionsModel: ObservableObject {
    /// 「プライバシー設定」の項目を出すか
    @Published private(set) var isVisible = false

    private let eligibility: AdEligibility
    private let presenter: PrivacyOptionsPresenting

    init(eligibility: AdEligibility, presenter: PrivacyOptionsPresenting) {
        self.eligibility = eligibility
        self.presenter = presenter
        refresh()
    }

    /// 項目を出すかを読み直す。必要かどうかは起動時の同意情報の更新（`AdsStartup`）で決まる
    func refresh() {
        isVisible = eligibility.isAdsEnabled && presenter.isPrivacyOptionsRequired
    }

    /// フォームを出す。失敗しても設定画面はそのまま使える
    func present() async {
        guard isVisible else { return }
        do {
            try await presenter.presentPrivacyOptions()
        } catch {
            print("プライバシー設定のフォームを表示できませんでした: \(error)")
        }
        refresh()
    }
}
