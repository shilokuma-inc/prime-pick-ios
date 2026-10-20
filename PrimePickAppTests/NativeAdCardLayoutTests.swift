//
//  NativeAdCardLayoutTests.swift
//  PrimePickAppTests
//

import GoogleMobileAds
import XCTest
@testable import PrimePickApp

final class NativeAdCardLayoutTests: XCTestCase {

    /// ポリシーが必須とする要素がそろっていること。「広告」と分かる表示・AdChoices アイコンの表示領域・メディア
    func testHasRequiredElements() {
        let adView = makeLaidOutAdView()

        XCTAssertNotNil(adView.adChoicesView, "AdChoices アイコンの表示領域が無い")
        // 大きさが無いと AdChoices アイコンが出ない（ポリシーで必要な表示）
        XCTAssertEqual(adView.adChoicesView?.frame.width ?? 0, 20, "AdChoices の表示領域の幅が足りない")
        XCTAssertEqual(adView.adChoicesView?.frame.height ?? 0, 20, "AdChoices の表示領域の高さが足りない")
        XCTAssertNotNil(adView.mediaView, "メディアの表示領域が無い")

        let labels = subviews(of: adView).compactMap { $0 as? UILabel }.compactMap(\.text)
        XCTAssertTrue(labels.contains(String(localized: "Ad")), "「広告」と分かる表示が無い: \(labels)")

        // 実際に描くのは読み込み後だが、アセットを流し込むビューは先に用意しておく
        XCTAssertTrue(subviews(of: adView).contains { $0 is UIImageView }, "アイコンの表示領域が無い")
        XCTAssertTrue(subviews(of: adView).contains { $0 is UIButton }, "行動を促すボタンの表示領域が無い")
    }

    /// カードの高さを決めてレイアウトしたときに、メディアが残りを埋めること
    func testMediaFillsRemainingHeight() {
        let adView = makeLaidOutAdView()

        let mediaView = adView.mediaView
        XCTAssertNotNil(mediaView, "メディアの表示領域が無い")
        // SDK は 120pt 未満のメディアを「小さすぎる」と警告する（将来は収益化の対象から外れる）
        XCTAssertGreaterThanOrEqual(mediaView?.frame.height ?? 0, 120, "メディアが小さすぎる")

        // カードからはみ出さない
        for view in subviews(of: adView) {
            let frame = view.convert(view.bounds, to: adView)
            XCTAssertGreaterThanOrEqual(frame.minY, -1, "\(type(of: view)) が上にはみ出している")
            XCTAssertLessThanOrEqual(frame.maxY, adView.bounds.height + 1, "\(type(of: view)) が下にはみ出している")
        }
    }

    /// 幅 350pt・カードの高さ `AdNativeAdView.defaultHeight` でレイアウトしたもの（実機の幅と高さに近い）
    private func makeLaidOutAdView() -> NativeAdView {
        let adView = NativeAdView()
        NativeAdCardLayout().install(in: adView)
        adView.frame = CGRect(x: 0, y: 0, width: 350, height: AdNativeAdView.defaultHeight)
        adView.layoutIfNeeded()
        return adView
    }

    private func subviews(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + subviews(of: $0) }
    }
}
