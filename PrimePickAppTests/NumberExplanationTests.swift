//
//  NumberExplanationTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class NumberExplanationTests: XCTestCase {

    func testPrimeNumber() {
        XCTAssertEqual(NumberExplanation(number: 17), .prime(17))
        XCTAssertEqual(NumberExplanation(number: 2), .prime(2))
    }

    func testCompositeNumberHasFactorsInAscendingOrder() {
        XCTAssertEqual(NumberExplanation(number: 91), .composite(91, factors: [7, 13]))
        XCTAssertEqual(NumberExplanation(number: 8), .composite(8, factors: [2, 2, 2]))
    }

    /// 1 は素数でも合成数でもない
    func testOneIsNeitherPrimeNorComposite() {
        XCTAssertEqual(NumberExplanation(number: 1), .neither(1))
    }
}
