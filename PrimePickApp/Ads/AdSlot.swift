//
//  AdSlot.swift
//  PrimePickApp
//

import SwiftUI

/// 広告の枠を出すか。SDK に依存しない部分だけを持って単体テストする
enum AdSlot: Equatable {
    /// 枠を出さない（レイアウトも変えない）
    case hidden
    /// 枠を確保して広告を読み込む
    case loading

    /// - Parameters:
    ///   - canShowAds: 撮影モード・テスト実行中でなく、その置き場所に出してよい（`AdEligibility.canShowAds(at:)`）
    ///   - isReadyToLoadAds: 起動時の同意フローと SDK の初期化が済んだ（`AdsStartup.isReadyToLoadAds`）
    ///   - didFailToLoad: 広告を読み込めなかった（在庫切れ・通信エラー）
    static func state(canShowAds: Bool, isReadyToLoadAds: Bool, didFailToLoad: Bool) -> AdSlot {
        // 枠は読み込みを始める時点で確保し、読み込めたあとに置いた画面がずれないようにする（一覧では行が増え、結果画面ではボタンが動く）。
        // 読み込めなかったら枠ごと消す
        canShowAds && isReadyToLoadAds && !didFailToLoad ? .loading : .hidden
    }

    /// 一度も表示できずに枠を閉じたあと、読み込み直すまでの間隔。在庫切れのときに短い間隔でリクエストを繰り返さない
    static let retryDelay: Duration = .seconds(60)

    /// 読み込みに失敗したときに枠を消すか。一度表示できたあとの失敗（自動リフレッシュの失敗）では、
    /// SDK が前の広告を出したままにするので枠を残す
    static func collapsesOnFailure(hasReceivedAd: Bool) -> Bool {
        !hasReceivedAd
    }
}

extension View {
    /// 広告を読み込めずに枠を閉じたとき、`AdSlot.retryDelay` のあとに読み込み直す。
    /// 失敗のフラグを戻すと SDK のビューが作り直され、新しいリクエストを送る
    func adRetriesOnFailure(_ didFailToLoad: Binding<Bool>) -> some View {
        task(id: didFailToLoad.wrappedValue) {
            guard didFailToLoad.wrappedValue else { return }
            try? await Task.sleep(for: AdSlot.retryDelay)
            guard !Task.isCancelled else { return }
            didFailToLoad.wrappedValue = false
        }
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
