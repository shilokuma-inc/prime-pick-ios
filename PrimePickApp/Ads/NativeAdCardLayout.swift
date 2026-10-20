//
//  NativeAdCardLayout.swift
//  PrimePickApp
//

import GoogleMobileAds
import UIKit

/// ネイティブ広告のカードのレイアウト（UIKit）
///
/// AdMob のネイティブ広告はテンプレートを使わず、レイアウトをアプリ側で組む。ポリシーが必須とする要素を必ず入れる:
/// 「広告」と分かる表示（`badgeLabel`）・広告主（`advertiserLabel`）・見出し（`headlineLabel`）・
/// AdChoices アイコンの表示領域（`adChoicesView`）。メディア（画像・動画）は残りの高さを埋め、
/// コンテンツと見分けがつかない配置にしない
final class NativeAdCardLayout {
    /// 「広告」と分かる表示（ポリシーで必須）
    private let badgeLabel = UILabel()
    /// AdChoices アイコンの表示領域（ポリシーで必須）。アイコンの中身は SDK が描く
    private let adChoicesView = AdChoicesView()
    /// 画像・動画。SDK が `mediaContent` を描く
    private let mediaView = MediaView()
    private let iconImageView = UIImageView()
    private let advertiserLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)

    private weak var adView: NativeAdView?

    private static let margin: CGFloat = 10
    private static let spacing: CGFloat = 6
    private static let iconSize: CGFloat = 40
    private static let adChoicesSize: CGFloat = 20
    private static let badgeHeight: CGFloat = 16
    private static let actionHeight: CGFloat = 34
    /// メディアの最小の高さ。カードの高さ（`AdNativeAdView.defaultHeight`）から文字の分を引いた残りを埋める。
    /// SDK は幅・高さが 120pt 未満のメディアを「小さすぎる」と警告し、将来は収益化の対象から外すため、
    /// 120pt を下回らないようにする（大きい文字の設定では入りきらないので、優先度を下げて譲る）
    private static let mediaMinHeight: CGFloat = 120

    /// レイアウトを組んで `NativeAdView` のアセットビューに設定する。読み込んだ内容は `render(_:)` で流し込む
    func install(in adView: NativeAdView) {
        self.adView = adView
        styleViews()
        let content = makeContentStack()
        content.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: adView.topAnchor),
            content.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
        ])
        // AdChoices は `nativeAd` を設定する前に決めておく（あとから差し替えられない）
        adView.adChoicesView = adChoicesView
        adView.mediaView = mediaView
    }

    /// 読み込んだ広告の内容を流し込む。無いアセットは隠し、そのアセットビューを SDK に要求させない
    func render(_ nativeAd: NativeAd) {
        guard let adView else { return }

        headlineLabel.text = nativeAd.headline
        adView.headlineView = nativeAd.headline == nil ? nil : headlineLabel

        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        adView.bodyView = nativeAd.body == nil ? nil : bodyLabel

        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        adView.advertiserView = nativeAd.advertiser == nil ? nil : advertiserLabel

        iconImageView.image = nativeAd.icon?.image
        iconImageView.isHidden = nativeAd.icon?.image == nil
        adView.iconView = nativeAd.icon?.image == nil ? nil : iconImageView

        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction == nil
        adView.callToActionView = nativeAd.callToAction == nil ? nil : callToActionButton

        // `nativeAd` を設定したあとにメディアの内容を渡す（SDK はこの順でメディアを描く）
        adView.nativeAd = nativeAd
        mediaView.mediaContent = nativeAd.mediaContent
    }

    private func makeContentStack() -> UIStackView {
        let header = UIStackView(arrangedSubviews: [badgeLabel, UIView(), adChoicesView])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = Self.spacing

        let infoText = UIStackView(arrangedSubviews: [advertiserLabel, headlineLabel])
        infoText.axis = .vertical
        infoText.spacing = 0

        let info = UIStackView(arrangedSubviews: [iconImageView, infoText])
        info.axis = .horizontal
        info.alignment = .top
        info.spacing = Self.spacing

        let content = UIStackView(arrangedSubviews: [header, mediaView, info, bodyLabel, callToActionButton])
        content.axis = .vertical
        content.spacing = Self.spacing
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(
            top: Self.margin,
            left: Self.margin,
            bottom: Self.margin,
            right: Self.margin
        )
        return content
    }

    private func styleViews() {
        badgeLabel.text = String(localized: "Ad")
        badgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .secondaryLabel
        badgeLabel.textAlignment = .center
        badgeLabel.backgroundColor = .tertiarySystemFill
        badgeLabel.layer.cornerRadius = 4
        badgeLabel.clipsToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            badgeLabel.widthAnchor.constraint(equalToConstant: 32),
            badgeLabel.heightAnchor.constraint(equalToConstant: Self.badgeHeight)
        ])

        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        adChoicesView.setContentHuggingPriority(.required, for: .horizontal)
        adChoicesView.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            adChoicesView.widthAnchor.constraint(equalToConstant: Self.adChoicesSize),
            adChoicesView.heightAnchor.constraint(equalToConstant: Self.adChoicesSize)
        ])

        mediaView.backgroundColor = .secondarySystemFill
        mediaView.layer.cornerRadius = 8
        mediaView.clipsToBounds = true
        mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
        mediaView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        // カードの高さが決まっていれば、この最小の高さは自然に満たされる。満たせないとき（大きい文字）は
        // 破らずに譲る（必須にすると制約の衝突でレイアウトが崩れる）
        let mediaMinHeight = mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.mediaMinHeight)
        mediaMinHeight.priority = .defaultHigh
        mediaMinHeight.isActive = true

        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])

        advertiserLabel.font = .systemFont(ofSize: 11)
        advertiserLabel.textColor = .secondaryLabel
        advertiserLabel.numberOfLines = 1

        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2

        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = UIColor(named: "appGreen") ?? .systemGreen
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.clipsToBounds = true
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.setContentHuggingPriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            callToActionButton.heightAnchor.constraint(equalToConstant: Self.actionHeight)
        ])

        // 見出しが無いときは、アイコンと本文だけの行になっても高さが保てるようにする
        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
