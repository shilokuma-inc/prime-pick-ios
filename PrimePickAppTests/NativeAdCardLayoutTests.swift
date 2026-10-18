//
//  NativeAdCardLayoutTests.swift
//  PrimePickAppTests
//

import GoogleMobileAds
import XCTest
@testable import PrimePickApp

final class NativeAdCardLayoutTests: XCTestCase {

    /// ポリシーが必須とする要素がそろっていること。「広告」と分かる表示・AdChoices アイコンの表示領域・メディア
    func testHasRequiredElements() throws {
        let adView = NativeAdView()
        NativeAdCardLayout().install(in: adView)

        XCTAssertNotNil(adView.adChoicesView, "AdChoices アイコンの表示領域が無い")
        XCTAssertNotNil(adView.mediaView, "メディアの表示領域が無い")

        let labels = subviews(of: adView).compactMap { $0 as? UILabel }.compactMap(\.text)
        XCTAssertTrue(labels.contains(String(localized: "Ad")), "「広告」と分かる表示が無い: \(labels)")

        // 実際に描くのは読み込み後だが、アセットを流し込むビューは先に用意しておく
        XCTAssertTrue(subviews(of: adView).contains { $0 is UIImageView }, "アイコンの表示領域が無い")
        XCTAssertTrue(subviews(of: adView).contains { $0 is UIButton }, "行動を促すボタンの表示領域が無い")
    }

    /// カードの高さを決めてレイアウトしたときに、メディアが残りを埋めること
    func testMediaFillsRemainingHeight() {
        let adView = NativeAdView()
        NativeAdCardLayout().install(in: adView)
        adView.frame = CGRect(x: 0, y: 0, width: 350, height: AdNativeAdView.defaultHeight)
        adView.layoutIfNeeded()

        let mediaView = adView.mediaView
        XCTAssertNotNil(mediaView, "メディアの表示領域が無い")
        XCTAssertGreaterThan(mediaView?.frame.height ?? 0, 50, "メディアが小さすぎる")

        // カードからはみ出さない
        for view in subviews(of: adView) {
            let frame = view.convert(view.bounds, to: adView)
            XCTAssertGreaterThanOrEqual(frame.minY, -1, "\(type(of: view)) が上にはみ出している")
            XCTAssertLessThanOrEqual(frame.maxY, adView.bounds.height + 1, "\(type(of: view)) が下にはみ出している")
        }
    }

    private func subviews(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + subviews(of: $0) }
    }
}
