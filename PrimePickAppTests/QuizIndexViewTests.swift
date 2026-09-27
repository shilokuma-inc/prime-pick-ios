//
//  QuizIndexViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizIndexViewTests: XCTestCase {

    // MARK: - コンボ倍率の表示

    func testMultiplierTextShowsOneDecimalPlace() {
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 2), "×1.1")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 7), "×1.6")
    }

    /// 上限に達したあとは 2.0 倍のまま増えない
    func testMultiplierTextIsCappedAtMaxMultiplier() {
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 11), "×2.0")
        XCTAssertEqual(QuizIndexView.multiplierText(combo: 100), "×2.0")
    }
}
