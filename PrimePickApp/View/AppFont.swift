//
//  AppFont.swift
//  PrimePickApp
//

import SwiftUI
import UIKit

/// 見出し・ボタン・数字に使う書体の組み合わせ（Discussion #409）
///
/// 書体を差し替えるときは `current` を替える。使ってよいのは iOS に標準で入っている書体だけ（フォントファイルは同梱しない）
struct AppTypeface: Equatable {
    /// 書体の指定
    enum Face: Equatable {
        /// システムの書体（SF）。`design` で丸ゴシックなどを選ぶ
        case system(Font.Design)
        /// iOS に標準で入っている書体を PostScript 名で指定する。名前を間違えるとシステムの書体に黙って落ちる
        case named(String)
        /// 欧文の書体（PostScript 名）に、日本語の文字だけ別の書体（`japanese`）を組み合わせる
        ///
        /// 欧文の書体だけを指定すると、日本語の文字はシステムの和文（ヒラギノ角ゴシック）に落ちるため。
        /// `UIFont` を組み立てて使うので、`AppFont.weight` は効かない（太さは PostScript 名で選ぶ）
        case namedWithJapanese(String, japanese: String)

        /// この書体で使う PostScript 名（システムの書体なら空）
        var postScriptNames: [String] {
            switch self {
            case .system: []
            case let .named(name): [name]
            case let .namedWithJapanese(name, japanese): [name, japanese]
            }
        }
    }

    /// 見出し・ボタン
    let heading: Face
    /// 出題の数字・スコアなどの数字と、ゲームの表示の文字
    let number: Face

    /// 今までの書体（見出し・ボタンは SF Rounded、数字は Arial Rounded MT Bold）
    static let standard = AppTypeface(heading: .system(.rounded), number: .named("ArialRoundedMTBold"))

    /// アプリで使う書体
    ///
    /// DEBUG ビルドでは、起動引数 `-title-logo-candidate <番号>` で選んだロゴの案の書体にする（Issue #415）
    static var current: AppTypeface {
        #if DEBUG
        if let candidate = TitleLogoCandidate.active {
            return candidate.typeface
        }
        #endif
        return standard
    }
}

/// 役割ごとの書体と大きさ・太さ
///
/// 直接 `.custom` や `.system(design: .rounded)` を書かず、これを `.appFont(_:)` で使う
struct AppFont: Equatable {
    /// 大きさの決め方。Dynamic Type での拡大のされ方が変わるので、置き換えるときは今と同じものを選ぶ
    enum Size: Equatable {
        /// Dynamic Type で拡大しない（`.system(size:)` と同じ）
        case fixed(CGFloat)
        /// Dynamic Type で拡大する（`.custom(_:size:)` と同じ。本文の大きさに合わせて拡大する）
        case scaled(CGFloat)
        /// テキストスタイルの大きさにする（Dynamic Type で拡大する）
        case textStyle(Font.TextStyle)
    }

    let face: AppTypeface.Face
    let size: Size
    /// nil なら書体のままの太さ
    let weight: Font.Weight?

    /// 見出し・ボタン。大きさは Dynamic Type で拡大しない
    static func heading(size: CGFloat, weight: Font.Weight, typeface: AppTypeface = .current) -> AppFont {
        AppFont(face: typeface.heading, size: .fixed(size), weight: weight)
    }

    /// 見出し・ボタン。テキストスタイルの大きさにする
    static func heading(_ style: Font.TextStyle, weight: Font.Weight, typeface: AppTypeface = .current) -> AppFont {
        AppFont(face: typeface.heading, size: .textStyle(style), weight: weight)
    }

    /// 数字。大きさは Dynamic Type で拡大する（今までの `.custom("ArialRoundedMTBold", size:)` と同じ）
    static func number(size: CGFloat, weight: Font.Weight? = nil, typeface: AppTypeface = .current) -> AppFont {
        AppFont(face: typeface.number, size: .scaled(size), weight: weight)
    }

    var font: Font {
        switch (face, size) {
        case let (.system(design), .fixed(size)):
            .system(size: size, weight: weight, design: design)
        case let (.system(design), .scaled(size)):
            // システムの書体には、大きさを指定して Dynamic Type で拡大する API が無いため、
            // 同じ拡大のされ方になるよう本文のテキストスタイルを基準に大きさを合わせる
            .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: size), weight: weight, design: design)
        case let (.system(design), .textStyle(style)):
            .system(style, design: design, weight: weight)
        case let (.named(name), .fixed(size)):
            Font.custom(name, fixedSize: size).applyingWeight(weight)
        case let (.named(name), .scaled(size)):
            Font.custom(name, size: size).applyingWeight(weight)
        case let (.named(name), .textStyle(style)):
            Font.custom(name, size: Self.defaultPointSize(of: style), relativeTo: style).applyingWeight(weight)
        case let (.namedWithJapanese(name, japanese), size):
            Font(Self.cascadedUIFont(name: name, japanese: japanese, size: size))
        }
    }

    /// 欧文の書体に和文の書体を組み合わせた `UIFont`
    ///
    /// Dynamic Type で拡大する大きさは、組み立てた時点の文字の大きさの設定で決まる
    static func cascadedUIFont(name: String, japanese: String, size: Size) -> UIFont {
        let pointSize: CGFloat
        let metrics: UIFontMetrics?
        switch size {
        case let .fixed(value):
            pointSize = value
            metrics = nil
        case let .scaled(value):
            pointSize = value
            metrics = UIFontMetrics(forTextStyle: .body)
        case let .textStyle(style):
            pointSize = defaultPointSize(of: style)
            metrics = UIFontMetrics(forTextStyle: uiTextStyle(of: style))
        }
        let descriptor = UIFontDescriptor(name: name, size: pointSize)
            .addingAttributes([.cascadeList: [UIFontDescriptor(name: japanese, size: pointSize)]])
        let font = UIFont(descriptor: descriptor, size: pointSize)
        return metrics?.scaledFont(for: font) ?? font
    }

    static func uiTextStyle(of style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }

    /// テキストスタイルの既定（Large）の大きさ
    static func defaultPointSize(of style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}

private extension Font {
    func applyingWeight(_ weight: Font.Weight?) -> Font {
        guard let weight else { return self }
        return self.weight(weight)
    }
}

extension View {
    /// 役割ごとの書体（`AppFont`）を使う
    func appFont(_ appFont: AppFont) -> some View {
        font(appFont.font)
    }
}
