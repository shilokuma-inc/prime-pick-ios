//
//  AnswerChoiceTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AnswerChoiceTests: XCTestCase {

    func testPrimeChoiceAnswersPrime() {
        XCTAssertTrue(AnswerChoice.prime.isPrime)
    }

    func testNotPrimeChoiceAnswersNotPrime() {
        XCTAssertFalse(AnswerChoice.notPrime.isPrime)
    }

    /// 「素数ではない」と答えて、出題された数が合成数なら正解になる（選択肢自体は正誤を表さない）
    func testNotPrimeChoiceIsCorrectForCompositeNumber() {
        let record = QuizAnswerRecord(id: 0, number: 91, isPrime: false, answeredPrime: AnswerChoice.notPrime.isPrime)
        XCTAssertTrue(record.isAnswerCorrect)
    }
}
