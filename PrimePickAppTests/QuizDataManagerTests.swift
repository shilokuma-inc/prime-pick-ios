//
//  QuizDataManagerTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizDataManagerTests: XCTestCase {

    private let manager = QuizDataManager()

    // MARK: - 出題データ

    func testMakeQuizDataReturnsRequestedNumberOfQuestions() {
        for questionCount in QuizQuestionCount.allCases {
            var generator = SeededGenerator(seed: 1)
            let quizData = manager.makeQuizData(
                difficulty: .normal,
                range: .threeDigits,
                questionCount: questionCount,
                using: &generator
            )
            XCTAssertEqual(quizData.count, questionCount.value)
            XCTAssertEqual(quizData.map(\.quizId), Array(1...questionCount.value))
        }
    }

    func testMakeQuizDataStaysWithinSelectedRange() {
        for range in QuizRange.allCases {
            var generator = SeededGenerator(seed: 2)
            let quizData = manager.makeQuizData(
                difficulty: .normal,
                range: range,
                questionCount: .twenty,
                using: &generator
            )
            for quiz in quizData {
                XCTAssertTrue(range.bounds.contains(quiz.number), "\(quiz.number) が \(range.rawValue) の外")
            }
        }
    }

    func testMakeQuizDataMarksPrimeNumbersAsCorrect() {
        var generator = SeededGenerator(seed: 3)
        let quizData = manager.makeQuizData(
            difficulty: .hard,
            range: .fourDigits,
            questionCount: .twenty,
            using: &generator
        )
        for quiz in quizData {
            XCTAssertEqual(quiz.isCorrect, PrimeFactorization.isPrime(quiz.number), "\(quiz.number)")
        }
    }

    /// Hard は 2・3・5 の倍数を出題しない。
    /// 引き直しではなく候補から直接引く実装に変えたので、シードを変えても破れないことを確認する
    func testHardNeverProducesMultiplesOfTwoThreeOrFive() {
        for seed in UInt64(0)..<50 {
            for range in QuizRange.allCases {
                var generator = SeededGenerator(seed: seed)
                let quizData = manager.makeQuizData(
                    difficulty: .hard,
                    range: range,
                    questionCount: .twenty,
                    using: &generator
                )
                for quiz in quizData {
                    XCTAssertTrue(range.bounds.contains(quiz.number))
                    XCTAssertFalse(
                        quiz.number % 2 == 0 || quiz.number % 3 == 0 || quiz.number % 5 == 0,
                        "seed=\(seed) で 2・3・5 の倍数 \(quiz.number) が出題された"
                    )
                }
            }
        }
    }

    /// Easy / Normal は 2・3・5 の倍数を除外しないので、十分な回数を引けば必ず出てくる
    func testEasyAndNormalCanProduceMultiplesOfTwoThreeOrFive() {
        for difficulty in [Difficulty.easy, .normal] {
            var generator = SeededGenerator(seed: 4)
            let quizData = manager.makeQuizData(
                difficulty: difficulty,
                range: difficulty.defaultRange,
                questionCount: .twenty,
                using: &generator
            )
            XCTAssertTrue(
                quizData.contains { $0.number % 2 == 0 || $0.number % 3 == 0 || $0.number % 5 == 0 },
                "\(difficulty.rawValue) で 2・3・5 の倍数が 1 問も出なかった"
            )
        }
    }

    // MARK: - CoprimeToThirty

    func testCoprimeToThirtyCountMatchesBruteForce() {
        var expected = 0
        for upperBound in 0...3_000 {
            if upperBound > 0, upperBound % 2 != 0, upperBound % 3 != 0, upperBound % 5 != 0 {
                expected += 1
            }
            XCTAssertEqual(CoprimeToThirty.count(upTo: upperBound), expected, "upTo: \(upperBound)")
        }
    }

    func testCoprimeToThirtyValueMatchesBruteForce() {
        let candidates = (1...3_000).filter { $0 % 2 != 0 && $0 % 3 != 0 && $0 % 5 != 0 }
        for (index, candidate) in candidates.enumerated() {
            XCTAssertEqual(CoprimeToThirty.value(at: index), candidate, "index: \(index)")
        }
    }

    func testCoprimeToThirtyRandomValueCoversEveryCandidate() {
        let bounds = 1...99
        let candidates = bounds.filter { $0 % 2 != 0 && $0 % 3 != 0 && $0 % 5 != 0 }
        var generator = SeededGenerator(seed: 5)
        var drawn: Set<Int> = []
        for _ in 0..<10_000 {
            guard let value = CoprimeToThirty.randomValue(in: bounds, using: &generator) else {
                return XCTFail("候補があるのに nil が返った")
            }
            XCTAssertTrue(candidates.contains(value), "\(value) は候補ではない")
            drawn.insert(value)
        }
        XCTAssertEqual(drawn, Set(candidates), "引かれなかった候補がある")
    }

    /// 候補が 1 つもないレンジでは無限ループせず nil を返す
    func testCoprimeToThirtyRandomValueReturnsNilWhenNoCandidateExists() {
        var generator = SeededGenerator(seed: 6)
        XCTAssertNil(CoprimeToThirty.randomValue(in: 2...6, using: &generator))
        XCTAssertNil(CoprimeToThirty.randomValue(in: 20...22, using: &generator))
    }

    // MARK: - SeededGenerator

    func testSeededGeneratorIsDeterministic() {
        var first = SeededGenerator(seed: 2024)
        var second = SeededGenerator(seed: 2024)
        var third = SeededGenerator(seed: 2025)

        let firstValues = (0..<100).map { _ in first.next() }
        XCTAssertEqual(firstValues, (0..<100).map { _ in second.next() })
        XCTAssertNotEqual(firstValues, (0..<100).map { _ in third.next() })
    }

    /// `nextUniform()` を使っていた頃は下位 40bit 前後が常に 0 だった。
    /// 64bit 全体を埋めていることを確認する
    func testSeededGeneratorFillsLowBits() {
        var generator = SeededGenerator(seed: 7)
        var lowBits: Set<UInt64> = []
        var minimumTrailingZeros = 64

        for _ in 0..<10_000 {
            let value = generator.next()
            lowBits.insert(value & 0xFF)
            minimumTrailingZeros = min(minimumTrailingZeros, value.trailingZeroBitCount)
        }

        XCTAssertEqual(lowBits.count, 256, "下位 8bit に出現しない値がある")
        XCTAssertEqual(minimumTrailingZeros, 0, "常に下位ビットが 0 になっている")
    }

    /// `UInt64(nextUniform() * Float(UInt64.max))` は積が 2^64 になったときにトラップしていた。
    /// 十分な回数を引いてもクラッシュしないことを確認する
    func testSeededGeneratorDoesNotTrapOverManyDraws() {
        var generator = SeededGenerator(seed: 8)
        for _ in 0..<1_000_000 {
            _ = generator.next()
        }
    }
}
