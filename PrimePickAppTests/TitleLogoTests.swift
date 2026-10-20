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

    func testWordsSpellPrimePick() {
        XCTAssertEqual(String(TitleLogoGlyphs.firstWord), "PRIME")
        XCTAssertEqual(String(TitleLogoGlyphs.secondWord), "PICK")
    }

    func testIsPrime() {
        XCTAssertEqual((0...30).filter(TitleLogoGlyphs.isPrime), [2, 3, 5, 7, 11, 13, 17, 19, 23, 29])
    }

    // MARK: - ふるい

    func testSieveRowsCoverOneToTwentyThree() {
        XCTAssertEqual(TitleLogoGlyphs.sieveRows.map { $0.map(\.number) }, [Array(1...11), Array(12...23)])
    }

    func testSieveRowsPlaceLettersOnPrimesOnly() {
        for row in TitleLogoGlyphs.sieveRows {
            for cell in row {
                XCTAssertEqual(cell.letter != nil, TitleLogoGlyphs.isPrime(cell.number), "\(cell.number)")
            }
        }
        XCTAssertEqual(String(TitleLogoGlyphs.sieveRows[0].compactMap(\.letter)), "PRIME")
        XCTAssertEqual(String(TitleLogoGlyphs.sieveRows[1].compactMap(\.letter)), "PICK")
        XCTAssertEqual(TitleLogoGlyphs.sieveRows.flatMap { $0 }.filter { $0.letter != nil }.map(\.number), [2, 3, 5, 7, 11, 13, 17, 19, 23])
    }

    func testSieveRowLeavesExtraPrimesEmpty() {
        let row = TitleLogoGlyphs.sieveRow(1...7, letters: Array("AB"))
        XCTAssertEqual(row.compactMap(\.letter), ["A", "B"])
        XCTAssertNil(row.first { $0.number == 5 }?.letter)
    }

    // MARK: - 書体と大きさ

    /// 名前を間違えるとシステムの書体に黙って落ちるため、iOS に入っていることを確かめる
    func testLogoFontIsInstalled() {
        XCTAssertNotNil(UIFont(name: TitleLogoLayout.fontName, size: 34))
    }

    func testScale() {
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: false, isCompact: false), 1)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: false, isCompact: true), 0.75)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: true, isCompact: false), 1.6)
        XCTAssertEqual(TitleLogoLayout.scale(isRegularWidth: true, isCompact: true), 1.6)
    }

    /// 文字の層と飾りの層は同じ大きさで重なる（ずれると文字がマスからはみ出す）
    @MainActor
    func testLettersAndDecorationLayersHaveSameSize() throws {
        for scale in [0.75, 1, 1.6] as [CGFloat] {
            let letters = ImageRenderer(content: TitleLogoArtwork(layer: .letters, scale: scale)).uiImage
            let decoration = ImageRenderer(content: TitleLogoArtwork(layer: .decoration, scale: scale)).uiImage
            let lettersSize = try XCTUnwrap(letters?.size)
            XCTAssertEqual(lettersSize, try XCTUnwrap(decoration?.size), "scale \(scale)")
            // iPhone SE の幅（375pt）から余白を引いた幅に収まる
            if scale <= 1 {
                XCTAssertLessThanOrEqual(lettersSize.width, 327, "scale \(scale)")
            }
        }
    }
}
