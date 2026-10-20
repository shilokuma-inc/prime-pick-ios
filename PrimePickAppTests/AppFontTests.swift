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

    func testCurrentTypefaceIsStandard() {
        XCTAssertEqual(AppTypeface.current, .standard)
    }

    /// 名前を間違えるとエラーにならずにシステムの書体に落ちるため、iOS に入っていることを確かめる
    func testNamedFacesAreInstalled() {
        for face in [AppTypeface.current.heading, AppTypeface.current.number] {
            guard case let .named(name) = face else { continue }
            let font = UIFont(name: name, size: 20)
            XCTAssertNotNil(font, name)
            XCTAssertEqual(font?.pointSize, 20)
        }
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

    func testDefaultPointSizes() {
        XCTAssertEqual(AppFont.defaultPointSize(of: .subheadline), 15)
        XCTAssertEqual(AppFont.defaultPointSize(of: .body), 17)
        XCTAssertEqual(AppFont.defaultPointSize(of: .largeTitle), 34)
    }
}
