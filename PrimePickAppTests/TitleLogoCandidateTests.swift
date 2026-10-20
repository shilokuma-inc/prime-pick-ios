//
//  TitleLogoCandidateTests.swift
//  PrimePickAppTests
//

import UIKit
import XCTest
@testable import PrimePickApp

final class TitleLogoCandidateTests: XCTestCase {

    // MARK: - 文字と素数

    func testLettersSpellPrimePick() {
        XCTAssertEqual(String(TitleLogoGlyphs.firstWord), "PRIME")
        XCTAssertEqual(String(TitleLogoGlyphs.secondWord), "PICK")
        XCTAssertEqual(String(TitleLogoGlyphs.letters), "PRIMEPICK")
    }

    func testIsPrime() {
        XCTAssertEqual((0...30).filter(TitleLogoGlyphs.isPrime), [2, 3, 5, 7, 11, 13, 17, 19, 23, 29])
    }

    func testLetterPrimesAreFirstNinePrimes() {
        XCTAssertEqual(TitleLogoGlyphs.letterPrimes, [2, 3, 5, 7, 11, 13, 17, 19, 23])
        XCTAssertEqual(TitleLogoGlyphs.letterPrimes.count, TitleLogoGlyphs.letters.count)
    }

    func testScrabbleValuesArePrimeAndCoverEveryLetter() {
        for letter in TitleLogoGlyphs.letters {
            let value = try? XCTUnwrap(TitleLogoGlyphs.scrabbleValues[letter])
            XCTAssertTrue(TitleLogoGlyphs.isPrime(value ?? 0), "\(letter)")
        }
        // 文字ごとに違う点数にする
        XCTAssertEqual(Set(TitleLogoGlyphs.scrabbleValues.values).count, TitleLogoGlyphs.scrabbleValues.count)
    }

    // MARK: - ふるい

    func testSieveRowsPlaceLettersOnPrimesOnly() {
        let rows = TitleLogoGlyphs.sieveRows
        XCTAssertEqual(rows.map { $0.map(\.number) }, [Array(1...11), Array(12...23)])
        for row in rows {
            for cell in row {
                XCTAssertEqual(cell.letter != nil, TitleLogoGlyphs.isPrime(cell.number), "\(cell.number)")
            }
        }
        XCTAssertEqual(String(rows[0].compactMap(\.letter)), "PRIME")
        XCTAssertEqual(String(rows[1].compactMap(\.letter)), "PICK")
    }

    // MARK: - 周期表

    func testElementTilesSpellPrimePickWithPrimeNumbers() {
        let rows = TitleLogoGlyphs.elementRows
        XCTAssertEqual(rows.map { $0.map(\.symbol).joined() }, ["PrIMe", "PiCk"])
        for tile in rows.flatMap({ $0 }) {
            XCTAssertTrue(TitleLogoGlyphs.isPrime(tile.number), tile.symbol)
        }
    }

    // MARK: - ドットマトリクス

    func testDotMatrixHasGlyphForEveryLetter() {
        for letter in TitleLogoGlyphs.letters {
            let glyph = TitleLogoGlyphs.dotMatrix[letter]
            XCTAssertEqual(glyph?.count, 7, "\(letter)")
            XCTAssertTrue(glyph?.allSatisfy { $0.count == 5 && $0.allSatisfy { "01".contains($0) } } ?? false, "\(letter)")
        }
    }

    func testDotRowsJoinLettersWithOneBlankColumn() {
        let rows = TitleLogoGlyphs.dotRows(for: TitleLogoGlyphs.firstWord)
        XCTAssertEqual(rows.count, 7)
        XCTAssertTrue(rows.allSatisfy { $0.count == 5 * 5 + 4 })
        // P の 1 行目は 11110、続けて 1 列あける
        XCTAssertEqual(Array(rows[0].prefix(6)), [true, true, true, true, false, false])
    }

    // MARK: - ウラムの螺旋

    func testUlamSpiralStartsAtCenterAndTurnsCounterclockwise() {
        let positions = TitleLogoGlyphs.ulamSpiral(side: 9)
        XCTAssertEqual(positions.count, 81)
        XCTAssertEqual(positions[1]?.column, 4)
        XCTAssertEqual(positions[1]?.row, 4)
        // 2 は右、3 は右上、4 は上、5 は左上
        XCTAssertEqual(positions[2].map { [$0.column, $0.row] }, [5, 4])
        XCTAssertEqual(positions[3].map { [$0.column, $0.row] }, [5, 3])
        XCTAssertEqual(positions[4].map { [$0.column, $0.row] }, [4, 3])
        XCTAssertEqual(positions[5].map { [$0.column, $0.row] }, [3, 3])
        // 81 は右下の角
        XCTAssertEqual(positions[81].map { [$0.column, $0.row] }, [8, 8])
        // すべてのマスに 1 つずつ置く
        XCTAssertEqual(Set(positions.values.map { $0.row * 9 + $0.column }).count, 81)
    }

    // MARK: - カクロ

    func testKakuroCluesAreSumsOfEachRow() {
        XCTAssertEqual(TitleLogoGlyphs.kakuroClues, [2 + 3 + 5 + 7 + 11, 13 + 17 + 19 + 23])
        XCTAssertEqual(TitleLogoGlyphs.kakuroClues, [28, 72])
    }

    // MARK: - 案の切り替え

    func testThereAreTenCandidatesNumberedOneToTen() {
        XCTAssertEqual(TitleLogoCandidate.allCases.map(\.rawValue), Array(1...10))
    }

    func testCandidateFromLaunchArguments() {
        XCTAssertEqual(TitleLogoCandidate.candidate(arguments: ["app", "-title-logo-candidate", "3"]), .sieve)
        XCTAssertEqual(TitleLogoCandidate.candidate(arguments: ["-title-logo-candidate", "10", "-screenshot-demo"]), .kakuro)
        XCTAssertNil(TitleLogoCandidate.candidate(arguments: ["app"]))
        XCTAssertNil(TitleLogoCandidate.candidate(arguments: ["-title-logo-candidate"]))
        XCTAssertNil(TitleLogoCandidate.candidate(arguments: ["-title-logo-candidate", "0"]))
        XCTAssertNil(TitleLogoCandidate.candidate(arguments: ["-title-logo-candidate", "11"]))
        XCTAssertNil(TitleLogoCandidate.candidate(arguments: ["-title-logo-candidate", "sudoku"]))
    }

    func testWithoutLaunchArgumentKeepsStandardTypeface() {
        // テストは起動引数なしで動く。引数なしのときは今の書体のまま
        XCTAssertNil(TitleLogoCandidate.active)
        XCTAssertEqual(AppTypeface.current, .standard)
    }

    /// 名前を間違えるとシステムの書体に黙って落ちるため、すべての案の書体が iOS に入っていることを確かめる
    func testEveryCandidateTypefaceIsInstalled() {
        for candidate in TitleLogoCandidate.allCases {
            let names = candidate.typeface.heading.postScriptNames + candidate.typeface.number.postScriptNames
            for name in names {
                XCTAssertNotNil(UIFont(name: name, size: 20), "案 \(candidate.rawValue): \(name)")
            }
        }
    }

    func testCandidatesUseDifferentLogoFonts() {
        let names = TitleLogoCandidate.allCases.map { $0.logoFontName ?? "system" }
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testCascadedFontUsesGivenSizeAndLatinFace() {
        let font = AppFont.cascadedUIFont(name: "Futura-Bold", japanese: "HiraginoSans-W6", size: .fixed(24))
        XCTAssertEqual(font.fontName, "Futura-Bold")
        XCTAssertEqual(font.pointSize, 24)
        let cascade = font.fontDescriptor.fontAttributes[.cascadeList] as? [UIFontDescriptor]
        XCTAssertEqual(cascade?.first?.postscriptName, "HiraginoSans-W6")
    }
}
