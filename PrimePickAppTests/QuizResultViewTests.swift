//
//  QuizResultViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizResultViewTests: XCTestCase {

    // MARK: - 正答率

    func testAccuracyPercentIsRounded() {
        XCTAssertEqual(QuizResultView.accuracyPercent(correctCount: 10, answeredCount: 10), 100)
        XCTAssertEqual(QuizResultView.accuracyPercent(correctCount: 0, answeredCount: 4), 0)
        // 2 / 3 = 66.66…% は 67%
        XCTAssertEqual(QuizResultView.accuracyPercent(correctCount: 2, answeredCount: 3), 67)
        // 1 / 3 = 33.33…% は 33%
        XCTAssertEqual(QuizResultView.accuracyPercent(correctCount: 1, answeredCount: 3), 33)
    }

    /// タイムアタックで 1 問も解かずに時間切れになった場合は 0 除算せず、正答率を出さない
    func testAccuracyPercentIsNilWithoutAnswers() {
        XCTAssertNil(QuizResultView.accuracyPercent(correctCount: 0, answeredCount: 0))
    }

    // MARK: - 内訳の点数表示

    func testSignedPointsText() {
        XCTAssertEqual(QuizResultView.signedPointsText(1_400), "+1400")
        XCTAssertEqual(QuizResultView.signedPointsText(0), "+0")
        XCTAssertEqual(QuizResultView.signedPointsText(-300), "\u{2212}300")
    }
}
