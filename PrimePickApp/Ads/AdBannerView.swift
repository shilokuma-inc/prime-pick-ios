//
//  AdBannerView.swift
//  PrimePickApp
//

import GoogleMobileAds
import SwiftUI

/// 画面の下部に置くアンカー型アダプティブバナー。幅は置いた場所いっぱい、高さは SDK が幅から決める
///
/// 撮影モード・テスト実行中・同意フローが済む前は何も出さない（枠も確保しない）。
/// 一度も表示できずに読み込みに失敗したら枠を閉じ、`AdBannerSlot.retryDelay` のあとに読み込み直す
struct AdBannerView: View {
    let placement: AdPlacement
    var eligibility: AdEligibility = .current
    var configuration: AdConfiguration? = .current

    @Environment(\.isAdsReadyToLoad) private var isReadyToLoadAds
    @State private var width: CGFloat = 0
    @State private var didFailToLoad = false
    @State private var hasReceivedAd = false

    var body: some View {
        let slot = AdBannerSlot.state(
            canShowBanner: eligibility.canShowBanner(at: placement),
            isReadyToLoadAds: isReadyToLoadAds,
            didFailToLoad: didFailToLoad
        )
        // 枠を閉じているあいだも再試行の task を動かすため、中身が無くても消えない入れ物に置く
        VStack(spacing: 0) {
            if slot == .loading, let configuration {
                banner(configuration: configuration)
            }
        }
        .task(id: didFailToLoad) {
            guard didFailToLoad else { return }
            try? await Task.sleep(for: AdBannerSlot.retryDelay)
            guard !Task.isCancelled else { return }
            // 枠を出し直すと BannerAdRepresentable が作り直され、新しいリクエストを送る
            didFailToLoad = false
        }
    }

    private func banner(configuration: AdConfiguration) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: width > 0 ? Self.adSize(width: width).size.height : 0)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { width = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, newWidth in
                            width = newWidth
                        }
                }
            }
            .overlay {
                if width > 0 {
                    BannerAdRepresentable(
                        adUnitID: configuration.bannerAdUnitID,
                        adSize: Self.adSize(width: width),
                        onReceive: { hasReceivedAd = true },
                        onFailure: {
                            if AdBannerSlot.collapsesOnFailure(hasReceivedAd: hasReceivedAd) {
                                didFailToLoad = true
                            }
                        }
                    )
                }
            }
    }

    private static func adSize(width: CGFloat) -> AdSize {
        largeAnchoredAdaptiveBanner(width: width)
    }
}

/// `BannerView` を SwiftUI に置く。作ったときに 1 回だけ読み込み、幅が変わったら大きさを変える（SDK が読み込み直す）
private struct BannerAdRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    let onReceive: () -> Void
    let onFailure: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReceive: onReceive, onFailure: onFailure)
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        context.coordinator.onReceive = onReceive
        context.coordinator.onFailure = onFailure
        if !isAdSizeEqualToSize(size1: banner.adSize, size2: adSize) {
            banner.adSize = adSize
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var onReceive: () -> Void
        var onFailure: () -> Void

        init(onReceive: @escaping () -> Void, onFailure: @escaping () -> Void) {
            self.onReceive = onReceive
            self.onFailure = onFailure
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            onReceive()
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("バナー広告を読み込めませんでした: \(error.localizedDescription)")
            onFailure()
        }
    }
}
