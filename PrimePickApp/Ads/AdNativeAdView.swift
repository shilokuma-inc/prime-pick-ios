//
//  AdNativeAdView.swift
//  PrimePickApp
//

import GoogleMobileAds
import SwiftUI
import UIKit

/// 一覧や結果画面に置くネイティブ広告（メディアありの大きめの広告）
///
/// 撮影モード・テスト実行中・同意フローが済む前は何も出さない（枠も確保しない）。
/// 一度も表示できずに読み込みに失敗したら枠を閉じ、`AdSlot.retryDelay` のあとに読み込み直す
struct AdNativeAdView: View {
    /// 出す置き場所。出す場所を変えるときは `AdPlacement` を直す
    let placement: AdPlacement
    var eligibility: AdEligibility = .current
    var configuration: AdConfiguration? = .current
    /// カードの高さ。枠を出すときはこの高さを確保する
    var height: CGFloat = Self.defaultHeight

    /// カードの高さ。メディアありの大きめの広告（Discussion #376 の決定で 250pt 前後）だが、
    /// 250pt だと文字の分を引いたメディアの領域が SDK の下限（120pt）を下回って
    /// 「メディアが小さすぎる」と警告されるため、メディアに十分な高さを残せる 300pt にする
    static let defaultHeight: CGFloat = 300

    @Environment(\.isAdsReadyToLoad) private var isReadyToLoadAds
    @State private var didFailToLoad = false
    @State private var hasReceivedAd = false

    var body: some View {
        let slot = AdSlot.state(
            canShowAds: eligibility.canShowAds(at: placement),
            isReadyToLoadAds: isReadyToLoadAds,
            didFailToLoad: didFailToLoad
        )
        // 枠を閉じているあいだは何も描かない（`List` に空の行・区切り・余白を残さない）。
        // 中身が無くても消えない入れ物（`Group`）に置き、枠を閉じているあいだも再試行の task を動かす
        Group {
            if slot == .loading, let configuration {
                NativeAdCard(
                    adUnitID: configuration.nativeAdUnitID,
                    onReceive: { hasReceivedAd = true },
                    onFailure: {
                        if AdSlot.collapsesOnFailure(hasReceivedAd: hasReceivedAd) {
                            didFailToLoad = true
                        }
                    }
                )
                .frame(height: height)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .adRetriesOnFailure($didFailToLoad)
    }
}

/// `NativeAdView`（SDK のアセットビュー）を SwiftUI に置く。作ったときに 1 回だけ読み込む
private struct NativeAdCard: UIViewRepresentable {
    let adUnitID: String
    let onReceive: () -> Void
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(adUnitID: adUnitID, onReceive: onReceive, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .clear
        context.coordinator.start(in: adView)
        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        context.coordinator.onReceive = onReceive
        context.coordinator.onFailure = onFailure
    }
}

extension NativeAdCard {
    /// ネイティブ広告の読み込みと、読み込んだ内容のレイアウトへの流し込み
    final class Coordinator: NSObject, NativeAdLoaderDelegate {
        var onReceive: () -> Void
        var onFailure: () -> Void

        private let adUnitID: String
        /// 保持しないと読み込みが止まる
        private var adLoader: AdLoader?
        private let layout = NativeAdCardLayout()

        init(adUnitID: String, onReceive: @escaping () -> Void, onFailure: @escaping () -> Void) {
            self.adUnitID = adUnitID
            self.onReceive = onReceive
            self.onFailure = onFailure
        }

        /// レイアウトを組んで読み込みを始める
        func start(in adView: NativeAdView) {
            layout.install(in: adView)

            let adLoader = AdLoader(
                adUnitID: adUnitID,
                // 広告をタップしたとき（App Store への遷移など）に出す画面。
                // シートの中に置いた広告からもタップできるよう、最前面の画面を渡す
                rootViewController: UIApplication.shared.adPresentationViewController,
                adTypes: [.native],
                // 画像・動画の縦横比は SDK に任せる（カードのメディアの領域に合わせて描かれる）
                options: [NativeAdMediaAdLoaderOptions()]
            )
            adLoader.delegate = self
            self.adLoader = adLoader
            adLoader.load(Request())
        }

        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            layout.render(nativeAd)
            onReceive()
        }

        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            print("ネイティブ広告を読み込めませんでした: \(error.localizedDescription)")
            onFailure()
        }
    }
}
