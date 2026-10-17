//
//  AdBannerSlot.swift
//  PrimePickApp
//

import SwiftUI

/// バナーの枠を出すか。SDK に依存しない判定だけを持ち、単体テストする
enum AdBannerSlot: Equatable {
    /// 枠を出さない（レイアウトも変えない）
    case hidden
    /// 枠を確保して広告を読み込む
    case loading

    /// - Parameters:
    ///   - canShowBanner: 撮影モード・テスト実行中でなく、その置き場所に出してよい（`AdEligibility.canShowBanner(at:)`）
    ///   - isReadyToLoadAds: 起動時の同意フローと SDK の初期化が済んだ（`AdsStartup.isReadyToLoadAds`）
    ///   - didFailToLoad: 広告を読み込めなかった（在庫切れ・通信エラー）
    static func state(canShowBanner: Bool, isReadyToLoadAds: Bool, didFailToLoad: Bool) -> AdBannerSlot {
        // 枠は読み込みを始める時点で確保し、読み込めたあとにボタンの位置がずれないようにする（誤タップを避ける）。
        // 読み込めなかったら枠ごと消す
        canShowBanner && isReadyToLoadAds && !didFailToLoad ? .loading : .hidden
    }
}

private struct AdsReadyToLoadKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// 広告を読み込んでよいか（`AdsStartup.isReadyToLoadAds`）。渡されていない画面（プレビューなど）では false
    var isAdsReadyToLoad: Bool {
        get { self[AdsReadyToLoadKey.self] }
        set { self[AdsReadyToLoadKey.self] = newValue }
    }
}
