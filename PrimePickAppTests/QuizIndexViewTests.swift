//
//  QuizIndexViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizIndexViewTests: XCTestCase {

    // MARK: - コンボ倍率の表示

    private let us = Locale(identifier: "en_US")

    func testMultiplierTextShowsOneDecimalPlace() {
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 2, locale: us), "×1.1")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 7, locale: us), "×1.6")
    }

    /// 上限に達したあとは 2.0 倍のまま増えない
    func testMultiplierTextIsCappedAtMaxMultiplier() {
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 11, locale: us), "×2.0")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 100, locale: us), "×2.0")
    }

    /// 小数点は地域の書式にする（#532）
    func testMultiplierTextUsesRegionDecimalSeparator() {
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 7, locale: Locale(identifier: "de_DE")), "×1,6")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 11, locale: Locale(identifier: "pt_BR")), "×2,0")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 7, locale: Locale(identifier: "ja_JP")), "×1.6")
    }
}
