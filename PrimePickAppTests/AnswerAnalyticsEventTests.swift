//
//  AnswerAnalyticsEventTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class AnswerAnalyticsEventTests: XCTestCase {

    func testEventName() {
        XCTAssertEqual(AnswerAnalyticsEvent.name, "answer")
    }

    func testParametersForCorrectAnswer() {
        let event = AnswerAnalyticsEvent(
            difficulty: .normal,
            range: .threeDigits,
            questionNumber: 1,
            isCorrect: true,
            elapsedSeconds: 2.5
        )
        let parameters = event.parameters

        XCTAssertEqual(parameters.count, 5)
        XCTAssertEqual(parameters["difficulty"] as? String, "Normal")
        XCTAssertEqual(parameters["quiz_range"] as? String, "100-999")
        XCTAssertEqual(parameters["question_number"] as? Int, 1)
        XCTAssertEqual(parameters["is_correct"] as? Int, 1)
        XCTAssertEqual(parameters["elapsed_seconds"] as? TimeInterval, 2.5)
    }

    func testIncorrectAnswerIsSentAsZero() {
        let event = AnswerAnalyticsEvent(
            difficulty: .easy,
            range: .oneOrTwoDigits,
            questionNumber: 3,
            isCorrect: false,
            elapsedSeconds: 0.8
        )

        XCTAssertEqual(event.parameters["is_correct"] as? Int, 0)
    }
}
