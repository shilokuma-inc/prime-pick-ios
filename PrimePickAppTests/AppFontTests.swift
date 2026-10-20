//
//  AppFontTests.swift
//  PrimePickAppTests
//

import SwiftUI
import UIKit
import XCTest
@testable import PrimePickApp

final class AppFontTests: XCTestCase {

    // MARK: - 書体

    func testStandardTypefaceKeepsCurrentFonts() {
        XCTAssertEqual(AppTypeface.standard.heading, .system(.rounded))
        XCTAssertEqual(AppTypeface.standard.number, .named("ArialRoundedMTBold"))
    }

    /// アプリの書体はタイトルのロゴ（Issue #415 の案 3）に合わせる
    func testCurrentTypefaceIsSieve() {
        XCTAssertEqual(AppTypeface.current, .sieve)
        XCTAssertEqual(AppTypeface.sieve.heading, .namedWithJapanese("Didot-Bold", japanese: "HiraMinProN-W6"))
        XCTAssertEqual(AppTypeface.sieve.number, .namedWithJapanese("Didot-Bold", japanese: "HiraMinProN-W6"))
        // ロゴの文字と同じ欧文の書体
        XCTAssertEqual(AppTypeface.sieve.heading.postScriptNames.first, TitleLogoLayout.fontName)
    }

    /// 名前を間違えるとエラーにならずにシステムの書体に落ちるため、iOS に入っていることを確かめる
    func testNamedFacesAreInstalled() {
        for typeface in [AppTypeface.current, .standard, .sieve] {
            for name in typeface.heading.postScriptNames + typeface.number.postScriptNames {
                let font = UIFont(name: name, size: 20)
                XCTAssertNotNil(font, name)
                XCTAssertEqual(font?.pointSize, 20)
            }
        }
    }

    func testPostScriptNames() {
        XCTAssertEqual(AppTypeface.Face.system(.rounded).postScriptNames, [])
        XCTAssertEqual(AppTypeface.Face.named("Didot-Bold").postScriptNames, ["Didot-Bold"])
        XCTAssertEqual(AppTypeface.Face.namedWithJapanese("Didot-Bold", japanese: "HiraMinProN-W6").postScriptNames, ["Didot-Bold", "HiraMinProN-W6"])
    }

    // MARK: - 役割 → 書体

    func testHeadingUsesHeadingFaceWithFixedSize() {
        let font = AppFont.heading(size: 24, weight: .bold)

        XCTAssertEqual(font.face, AppTypeface.current.heading)
        // `.system(size:)` と同じく Dynamic Type で拡大しない
        XCTAssertEqual(font.size, .fixed(24))
        XCTAssertEqual(font.weight, .bold)
    }

    func testHeadingWithTextStyle() {
        let font = AppFont.heading(.subheadline, weight: .bold)

        XCTAssertEqual(font.face, AppTypeface.current.heading)
        XCTAssertEqual(font.size, .textStyle(.subheadline))
        XCTAssertEqual(font.weight, .bold)
    }

    func testNumberUsesNumberFaceWithScaledSize() {
        let font = AppFont.number(size: 45)

        XCTAssertEqual(font.face, AppTypeface.current.number)
        // `.custom(_:size:)` と同じく Dynamic Type で拡大する
        XCTAssertEqual(font.size, .scaled(45))
        XCTAssertNil(font.weight)
    }

    func testRolesFollowGivenTypeface() {
        let typeface = AppTypeface(heading: .named("AvenirNext-Bold"), number: .system(.monospaced))

        XCTAssertEqual(AppFont.heading(size: 18, weight: .heavy, typeface: typeface).face, .named("AvenirNext-Bold"))
        XCTAssertEqual(AppFont.number(size: 22, typeface: typeface).face, .system(.monospaced))
    }

    /// 標準の書体では、置き換える前に書いていた `Font` と同じになる（見た目と Dynamic Type での拡大のされ方を変えない）
    func testStandardFontsMatchPreviousExpressions() {
        XCTAssertEqual(AppFont.heading(size: 24, weight: .bold, typeface: .standard).font, .system(size: 24, weight: .bold, design: .rounded))
        XCTAssertEqual(
            AppFont.heading(.subheadline, weight: .bold, typeface: .standard).font,
            .system(.subheadline, design: .rounded, weight: .bold)
        )
        XCTAssertEqual(AppFont.number(size: 45, typeface: .standard).font, .custom("ArialRoundedMTBold", size: 45))
        XCTAssertNotEqual(AppFont.number(size: 45, typeface: .standard).font, .custom("ArialRoundedMTBold", fixedSize: 45))
    }

    func testCascadedFontUsesGivenSizeAndLatinFace() {
        let font = AppFont.cascadedUIFont(name: "Futura-Bold", japanese: "HiraginoSans-W6", size: .fixed(24))
        XCTAssertEqual(font.fontName, "Futura-Bold")
        XCTAssertEqual(font.pointSize, 24)
        let cascade = font.fontDescriptor.fontAttributes[.cascadeList] as? [UIFontDescriptor]
        XCTAssertEqual(cascade?.first?.postscriptName, "HiraginoSans-W6")
    }

    /// Dynamic Type で拡大する大きさは、今の文字の大きさの設定で拡大した値になる
    func testCascadedFontScalesWithDynamicType() {
        let scaled = AppFont.cascadedUIFont(name: "Futura-Bold", japanese: "HiraginoSans-W6", size: .scaled(22))
        XCTAssertEqual(scaled.pointSize, UIFontMetrics(forTextStyle: .body).scaledValue(for: 22), accuracy: 0.01)
        XCTAssertEqual(scaled.fontName, "Futura-Bold")

        let textStyle = AppFont.cascadedUIFont(name: "Futura-Bold", japanese: "HiraginoSans-W6", size: .textStyle(.subheadline))
        XCTAssertEqual(textStyle.pointSize, UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 15), accuracy: 0.01)
    }

    /// SwiftUI の文字の大きさ（`.dynamicTypeSize`）で拡大する。拡大しない大きさは変わらない
    func testCascadedFontFollowsDynamicTypeSize() {
        let large = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(DynamicTypeSize.large))
        let huge = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(DynamicTypeSize.accessibility3))

        let scaledLarge = AppFont.cascadedUIFont(name: "Didot-Bold", japanese: "HiraMinProN-W6", size: .scaled(22), traits: large)
        let scaledHuge = AppFont.cascadedUIFont(name: "Didot-Bold", japanese: "HiraMinProN-W6", size: .scaled(22), traits: huge)
        XCTAssertEqual(scaledLarge.pointSize, 22, accuracy: 0.01)
        XCTAssertGreaterThan(scaledHuge.pointSize, scaledLarge.pointSize)

        let fixedHuge = AppFont.cascadedUIFont(name: "Didot-Bold", japanese: "HiraMinProN-W6", size: .fixed(22), traits: huge)
        XCTAssertEqual(fixedHuge.pointSize, 22)

        let styleHuge = AppFont.cascadedUIFont(name: "Didot-Bold", japanese: "HiraMinProN-W6", size: .textStyle(.headline), traits: huge)
        XCTAssertEqual(styleHuge.pointSize, UIFontMetrics(forTextStyle: .headline).scaledValue(for: 17, compatibleWith: huge), accuracy: 0.01)
    }

    /// `font(dynamicTypeSize:)` は渡した文字の大きさで拡大する
    func testFontFollowsGivenDynamicTypeSize() {
        let huge = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(DynamicTypeSize.accessibility3))
        let scaled = AppFont(face: .system(.rounded), size: .scaled(22), weight: .bold)
        XCTAssertEqual(
            scaled.font(dynamicTypeSize: .accessibility3),
            .system(size: UIFontMetrics(forTextStyle: .body).scaledValue(for: 22, compatibleWith: huge), weight: .bold, design: .rounded)
        )
        XCTAssertNotEqual(scaled.font(dynamicTypeSize: .accessibility3), scaled.font(dynamicTypeSize: .large))
        // 拡大しない大きさは文字の大きさによらない
        let fixed = AppFont.heading(size: 22, weight: .bold, typeface: .standard)
        XCTAssertEqual(fixed.font(dynamicTypeSize: .accessibility3), fixed.font(dynamicTypeSize: .large))
    }

    /// アプリの書体の日本語はヒラギノ明朝 W6 で描く
    func testSieveFontCascadesToMincho() {
        guard case let .namedWithJapanese(name, japanese) = AppTypeface.sieve.heading else {
            return XCTFail("和文を組み合わせた書体になっていない")
        }
        let font = AppFont.cascadedUIFont(name: name, japanese: japanese, size: .fixed(22))
        XCTAssertEqual(font.fontName, "Didot-Bold")
        let cascade = font.fontDescriptor.fontAttributes[.cascadeList] as? [UIFontDescriptor]
        XCTAssertEqual(cascade?.map(\.postscriptName), ["HiraMinProN-W6"])
    }

    func testNumberWithTextStyle() {
        let font = AppFont.number(.title)
        XCTAssertEqual(font.face, AppTypeface.current.number)
        XCTAssertEqual(font.size, .textStyle(.title))
        XCTAssertNil(font.weight)
    }

    func testDefaultPointSizes() {
        XCTAssertEqual(AppFont.defaultPointSize(of: .subheadline), 15)
        XCTAssertEqual(AppFont.defaultPointSize(of: .body), 17)
        XCTAssertEqual(AppFont.defaultPointSize(of: .largeTitle), 34)
    }
}
