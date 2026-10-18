//
//  GoogleMobileAdsServices.swift
//  PrimePickApp
//

import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// UMP の同意。同意が必要な地域（EU・英国など）の利用者にだけ同意フォームを出す
final class UserMessagingPlatformConsent: AdConsentGathering {
    func gatherConsent() async throws {
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
        try await ConsentForm.loadAndPresentIfRequired(from: UIApplication.shared.topViewController)
    }

    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }
}

/// 設定画面から出す、UMP のプライバシー オプション（同意のやり直し）のフォーム
final class UserMessagingPlatformPrivacyOptions: PrivacyOptionsPresenting {
    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    func presentPrivacyOptions() async throws {
        try await ConsentForm.presentPrivacyOptionsForm(from: UIApplication.shared.topViewController)
    }
}

/// ATT のダイアログ。許可した人にだけパーソナライズ広告が出る（許可しない人には SDK が非パーソナライズ広告を出す）
final class AppTrackingAuthorization: TrackingAuthorizationRequesting {
    func requestAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}

/// Google Mobile Ads SDK の初期化
final class GoogleMobileAdsStarter: MobileAdsStarting {
    func start() async {
        _ = await MobileAds.shared.start()
    }
}

extension AdsStartup {
    /// アプリで使う、実際の SDK につないだもの
    static func live() -> AdsStartup {
        AdsStartup(
            eligibility: .current,
            consent: UserMessagingPlatformConsent(),
            tracking: AppTrackingAuthorization(),
            mobileAds: GoogleMobileAdsStarter()
        )
    }
}

extension PrivacyOptionsModel {
    /// アプリで使う、実際の UMP につないだもの
    static func live() -> PrivacyOptionsModel {
        PrivacyOptionsModel(eligibility: .current, presenter: UserMessagingPlatformPrivacyOptions())
    }
}

private extension UIApplication {
    /// 同意フォームを出す画面。前面のウィンドウで最も手前に出ている画面を返す
    var topViewController: UIViewController? {
        var top = adPresentationRootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension UIApplication {
    /// 広告を出す画面。前面のウィンドウのルート（同意フォームはこの上に出し、広告のタップはここから遷移する）
    var adPresentationRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow?
            .rootViewController
    }
}
