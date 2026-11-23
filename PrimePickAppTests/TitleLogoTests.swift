//
//  TitleLogoTests.swift
//  PrimePickAppTests
//

import SwiftUI
import UIKit
import XCTest
@testable import PrimePickApp

final class TitleLogoTests: XCTestCase {

    // MARK: - 文字と素数

    func testIsPrime() {
        XCTAssertEqual((0...30).filter(TitleLogoGlyphs.isPrime), [2, 3, 5, 7, 11, 13, 17, 19, 23, 29])
    }

    func testLinesAreSplitByNewlines() {
        XCTAssertEqual(TitleLogoGlyphs.lines(from: "PRIME\nOR\nNOT?"), ["PRIME", "OR", "NOT?"])
        XCTAssertEqual(TitleLogoGlyphs.lines(from: "素数なの？"), ["素数なの？"])
        XCTAssertEqual(TitleLogoGlyphs.lines(from: "ECHT\n\nPRIM?\n"), ["ECHT", "PRIM?"])
    }

    /// 空白（フランス語の「?」の前の細い空白を含む）はマスにしない
    func testWhitespaceIsNotACell() {
        XCTAssertEqual(TitleLogoGlyphs.glyphs(of: "PREMIER\u{202F}?"), Array("PREMIER?"))
        XCTAssertEqual(TitleLogoGlyphs.glyphs(of: "¿SERÁ PRIMO?"), Array("¿SERÁPRIMO?"))
    }

    // MARK: - ふるい

    /// 今までのロゴ（PRIME / PICK）と同じ並びになる: 1 段目は 1〜11、2 段目は 12〜23
    func testSieveRowsOfPrimePick() {
        let rows = TitleLogoGlyphs.sieveRows(lines: ["PRIME", "PICK"])
        XCTAssertEqual(rows.map { $0.map(\.number) }, [Array(1...11), Array(12...23)])
        XCTAssertEqual(rows.map { String($0.compactMap(\.letter)) }, ["PRIME", "PICK"])
    }

    /// 数は行をまたいで続き、各行は最後の文字を載せた素数で終わる
    func testSieveRowsContinueAcrossLines() {
        let rows = TitleLogoGlyphs.sieveRows(lines: ["PRIME", "OR", "NOT?"])
        XCTAssertEqual(rows.map { $0.first?.number }, [1, 12, 18])
        XCTAssertEqual(rows.map { $0.last?.number }, [11, 17, 31])
        XCTAssertEqual(rows.map { String($0.compactMap(\.letter)) }, ["PRIME", "OR", "NOT?"])
    }

    func testSieveRowsPlaceLettersOnPrimesOnly() {
        let rows = TitleLogoGlyphs.sieveRows(lines: ["ECHT", "PRIM?"])
        for cell in rows.flatMap({ $0 }) {
            XCTAssertEqual(cell.letter != nil, TitleLogoGlyphs.isPrime(cell.number), "\(cell.number)")
        }
        XCTAssertEqual(rows.flatMap { $0 }.filter { $0.letter != nil }.map(\.number), [2, 3, 5, 7, 11, 13, 17, 19, 23])
    }

    func testSieveRowsSkipEmptyLines() {
        XCTAssertEqual(TitleLogoGlyphs.sieveRows(lines: ["", "AB"]).map { $0.map(\.number) }, [[1, 2, 3]])
    }

    func testSieveRowLeavesExtraPrimesEmpty() {
        let row = TitleLogoGlyphs.sieveRow(1...7, letters: Array("AB"))
        XCTAssertEqual(row.compactMap(\.letter), ["A", "B"])
        XCTAssertNil(row.first { $0.number == 5 }?.letter)
    }

    // MARK: - 言語ごとのアプリ名

    /// アプリに入っている言語（Base 以外）。knownRegions の 10 言語と、スペインのスペイン語（es-ES）
    private var localizations: [String] {
        Bundle.main.localizations.filter { $0 != "Base" }.sorted()
    }

    private func bundle(for localization: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: localization, ofType: "lproj"), localization)
        return try XCTUnwrap(Bundle(path: path), localization)
    }

    func testAppHasTenLanguagesAndSpainSpanish() {
        XCTAssertEqual(localizations, ["de", "en", "es", "es-ES", "fr", "it", "ja", "ko", "pt-BR", "zh-Hans", "zh-Hant"])
    }

    /// ロゴの文字は、その言語のホーム画面のアプリ名（CFBundleDisplayName）を大文字にして空白を除いたものと同じ
    func testLogoLinesSpellDisplayNameInEveryLanguage() throws {
        for localization in localizations {
            let bundle = try bundle(for: localization)
            let name = bundle.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist")
            let logo = bundle.localizedString(forKey: "TitleLogoLines", value: nil, table: nil)
            XCTAssertNotEqual(name, "CFBundleDisplayName", "\(localization) にアプリ名がありません")
            XCTAssertNotEqual(logo, "TitleLogoLines", "\(localization) にロゴの行がありません")

            let expected = TitleLogoGlyphs.glyphs(of: name.uppercased(with: Locale(identifier: localization)))
            let actual = TitleLogoGlyphs.lines(from: logo).flatMap(TitleLogoGlyphs.glyphs(of:))
            XCTAssertEqual(String(actual), String(expected), localization)
        }
    }

    // MARK: - 書体と大きさ

    /// 名前を間違えるとシステムの書体に黙って落ちるため、iOS に入っていることを確かめる
    func testLogoFontIsInstalled() {
        XCTAssertNotNil(UIFont(name: TitleLogoLayout.fontName, size: 34))
        XCTAssertNotNil(UIFont(name: TitleLogoLayout.japaneseFontName, size: 34))
    }

    func testScale() {
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: false, isCompact: false), 1)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: false, isCompact: true), 0.65)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: true, isCompact: false), 1.6)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: true, isCompact: true), 1.2)
    }

    func testNaturalWidth() {
        // 1〜11: 素数 5 マス（40pt）・合成数 6 マス（13pt）・間隔 10（2pt）
        XCTAssertEqual(TitleLogoLayout.naturalWidth(of: TitleLogoGlyphs.sieveRows(lines: ["PRIME", "PICK"])), 298)
    }

    /// 収まる名前は縮めず、長い名前（フランス語の 1〜19）は収まるまで縮める
    func testFittingScale() {
        XCTAssertEqual(TitleLogoLayout.fittingScale(for: TitleLogoGlyphs.sieveRows(lines: ["PRIME", "OR", "NOT?"])), 1)
        let long = TitleLogoGlyphs.sieveRows(lines: ["PREMIER\u{202F}?"])
        XCTAssertEqual(TitleLogoLayout.fittingScale(for: long), TitleLogoLayout.maxWidth / 499, accuracy: 0.0001)
    }

    /// 文字の層と飾りの層は同じ大きさで重なり（ずれると文字がマスからはみ出す）、どの言語も iPhone SE の幅に収まる
    @MainActor
    func testLettersAndDecorationLayersHaveSameSizeInEveryLanguage() throws {
        for localization in localizations {
            let logo = try bundle(for: localization).localizedString(forKey: "TitleLogoLines", value: nil, table: nil)
            let rows = TitleLogoGlyphs.sieveRows(lines: TitleLogoGlyphs.lines(from: logo))
            for baseScale in [0.65, 1, 1.2, 1.6] as [CGFloat] {
                let scale = baseScale * TitleLogoLayout.fittingScale(for: rows)
                let letters = ImageRenderer(content: TitleLogoArtwork(layer: .letters, rows: rows, scale: scale)).uiImage
                let decoration = ImageRenderer(content: TitleLogoArtwork(layer: .decoration, rows: rows, scale: scale)).uiImage
                let lettersSize = try XCTUnwrap(letters?.size)
                XCTAssertEqual(lettersSize, try XCTUnwrap(decoration?.size), "\(localization) scale \(baseScale)")
                if baseScale <= 1 {
                    XCTAssertLessThanOrEqual(lettersSize.width, TitleLogoLayout.maxWidth + 0.5, "\(localization) scale \(baseScale)")
                }
            }
        }
    }
}
