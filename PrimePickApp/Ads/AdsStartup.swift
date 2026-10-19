//
//  AdsStartup.swift
//  PrimePickApp
//

import Foundation

/// UMP（User Messaging Platform）の同意。SDK に依存する部分を包み、起動の順序を SDK 無しでテストできるようにする
@MainActor
protocol AdConsentGathering: AnyObject {
    /// 同意情報を更新し、同意が必要な地域では同意フォームを出す。失敗は throw する
    func gatherConsent() async throws
    /// 広告を読み込んでよいか（UMP の `canRequestAds`）。前回の起動で得た同意も含む
    var canRequestAds: Bool { get }
}

/// ATT（App Tracking Transparency）のダイアログ
@MainActor
protocol TrackingAuthorizationRequesting: AnyObject {
    /// まだ選んでいない利用者にだけダイアログを出す
    func requestAuthorizationIfNeeded() async
}

/// Google Mobile Ads SDK の初期化
@MainActor
protocol MobileAdsStarting: AnyObject {
    func start() async
}

/// 起動時の「UMP の同意 → ATT → 広告 SDK の初期化」を順に行う
///
/// 同意フローが失敗しても起動・画面の表示は止めない（前回までの同意で `canRequestAds` が true なら広告を出す）。
/// `isReadyToLoadAds` が true になるまでネイティブ広告は読み込まない
@MainActor
final class AdsStartup: ObservableObject {
    /// SDK の初期化が済み、広告を読み込んでよい
    @Published private(set) var isReadyToLoadAds = false

    private let eligibility: AdEligibility
    private let consent: AdConsentGathering
    private let tracking: TrackingAuthorizationRequesting
    private let mobileAds: MobileAdsStarting
    private var hasStarted = false

    init(
        eligibility: AdEligibility,
        consent: AdConsentGathering,
        tracking: TrackingAuthorizationRequesting,
        mobileAds: MobileAdsStarting
    ) {
        self.eligibility = eligibility
        self.consent = consent
        self.tracking = tracking
        self.mobileAds = mobileAds
    }

    /// アプリがアクティブになったときに呼ぶ（ATT はアクティブでないと出ないため）。
    /// SDK の初期化まで進んだあと・処理中は何もしない。同意が得られずに終わったときは、次にアクティブになったときにやり直す
    func startIfNeeded() async {
        // 撮影モード・テスト実行中は同意フォーム・ATT・SDK のどれも動かさない
        guard eligibility.isAdsEnabled, !hasStarted else { return }
        hasStarted = true

        do {
            try await consent.gatherConsent()
        } catch {
            print("広告の同意情報を取得できませんでした: \(error)")
        }
        // 同意が得られていない（同意フォームを閉じられない・取得に失敗した）あいだは、ATT も広告も出さない。
        // 一時的な通信エラーなどでこの起動中ずっと広告が出なくならないよう、次にアクティブになったときにやり直す
        guard consent.canRequestAds else {
            hasStarted = false
            return
        }

        await tracking.requestAuthorizationIfNeeded()
        await mobileAds.start()
        isReadyToLoadAds = true
    }
}
