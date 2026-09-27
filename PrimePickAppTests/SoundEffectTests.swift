//
//  SoundEffectTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class SoundEffectTests: XCTestCase {

    // MARK: - 正解音の音階

    func testCorrectNoteIndexRisesWithCombo() {
        let expected: [(combo: Int, note: Int)] = [
            // 通常段階は最低音
            (1, 0), (2, 0),
            // Good から 1 段ずつ上がる
            (3, 1), (4, 2), (5, 3),
            // Great の途中で最高音の手前に張り付く
            (6, 4), (7, 5), (8, 6), (10, 6),
            // MAX で最高音
            (11, 7), (50, 7)
        ]
        for (combo, note) in expected {
            XCTAssertEqual(SoundEffect.correctNoteIndex(combo: combo), note, "combo=\(combo)")
        }
    }

    func testCorrectNoteIndexNeverDecreases() {
        var previous = 0
        for combo in 0...30 {
            let note = SoundEffect.correctNoteIndex(combo: combo)
            XCTAssertGreaterThanOrEqual(note, previous)
            XCTAssertTrue((0..<SoundEffect.correctNoteCount).contains(note))
            previous = note
        }
    }

    // MARK: - 音源

    /// 正解音の 8 音はすべてアプリのバンドルに含まれている
    func testEveryCorrectNoteIsBundled() {
        let bundle = Bundle(for: QuizDataManager.self)
        for combo in [1, 3, 4, 5, 6, 7, 8, 11] {
            let name = SoundEffect.correct(combo: combo).resourceName
            XCTAssertNotNil(name)
            XCTAssertNotNil(
                bundle.url(forResource: name, withExtension: SoundFeedback.resourceExtension),
                "\(name ?? "nil").\(SoundFeedback.resourceExtension) がバンドルに無い"
            )
        }
    }

    func testIncorrectUsesSystemSound() {
        XCTAssertNil(SoundEffect.incorrect.resourceName)
        XCTAssertEqual(AnswerFeedback.incorrect.sound(combo: 0), .incorrect)
        XCTAssertEqual(AnswerFeedback.correct.sound(combo: 4), .correct(combo: 4))
    }
}
