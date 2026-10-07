//
//  QuizDataManagerTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizDataManagerTests: XCTestCase {

    private let manager = QuizDataManager(primeProbability: 0.5)

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

    /// `answer` イベントは問題ごとの難易度・レンジで送るため、既存のモードでは全問がプレイの設定と同じ値を持つこと
    func testMakeQuizDataCarriesRequestedDifficultyAndRange() {
        for difficulty in [Difficulty.easy, .normal, .hard] {
            for range in QuizRange.allCases {
                var generator = SeededGenerator(seed: 4)
                let quizData = manager.makeQuizData(
                    difficulty: difficulty,
                    range: range,
                    questionCount: .ten,
                    using: &generator
                )
                for quiz in quizData {
                    XCTAssertEqual(quiz.difficulty, difficulty)
                    XCTAssertEqual(quiz.range, range)
                }
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
                range: difficulty.range,
                questionCount: .twenty,
                using: &generator
            )
            XCTAssertTrue(
                quizData.contains { $0.number % 2 == 0 || $0.number % 3 == 0 || $0.number % 5 == 0 },
                "\(difficulty.rawValue) で 2・3・5 の倍数が 1 問も出なかった"
            )
        }
    }

    // MARK: - 素数の出現確率

    /// 1 プレイごとの確率は 0.3〜0.7 から引く。シードを変えても範囲を外れず、範囲の中で偏らないことを確認する
    func testPrimeProbabilityIsDrawnWithinRange() {
        var probabilities: [Double] = []
        for seed in UInt64(0)..<1_000 {
            var generator = SeededGenerator(seed: seed)
            let probability = QuizDataManager(using: &generator).primeProbability
            XCTAssertTrue(
                QuizDataManager.primeProbabilityRange.contains(probability),
                "seed=\(seed) で範囲外の確率 \(probability)"
            )
            probabilities.append(probability)
        }
        XCTAssertLessThan(probabilities.min()!, 0.35, "下限付近が引かれていない")
        XCTAssertGreaterThan(probabilities.max()!, 0.65, "上限付近が引かれていない")
    }

    /// 各問題は独立に確率 p で素数になるので、多数回出題すれば素数率は p に近づく
    func testPrimeRatioApproachesPrimeProbability() {
        for difficulty in [Difficulty.easy, .normal, .hard] {
            for probability in [0.3, 0.5, 0.7] {
                let manager = QuizDataManager(primeProbability: probability)
                var generator = SeededGenerator(seed: 9)
                var quizData: [QuizEntity] = []
                for _ in 0..<250 {
                    quizData += manager.makeQuizData(
                        difficulty: difficulty,
                        range: difficulty.range,
                        questionCount: .twenty,
                        using: &generator
                    )
                }
                let primeRatio = Double(quizData.filter(\.isCorrect).count) / Double(quizData.count)
                XCTAssertEqual(
                    primeRatio,
                    probability,
                    accuracy: 0.03,
                    "\(difficulty.rawValue) / p=\(probability) で素数率が \(primeRatio)"
                )
            }
        }
    }

    /// 同じプレイ中の補充（`makeQuizData` の再呼び出し）でも確率は変わらない
    func testPrimeProbabilityIsKeptAcrossRefills() {
        var generator = SeededGenerator(seed: 10)
        let manager = QuizDataManager(using: &generator)
        let probability = manager.primeProbability
        for _ in 0..<5 {
            _ = manager.makeQuizData(
                difficulty: .normal,
                range: .threeDigits,
                questionCount: .ten,
                using: &generator
            )
            XCTAssertEqual(manager.primeProbability, probability)
        }
    }

    // MARK: - 直近の重複回避

    /// Easy × 1-99 は素数が 25 個しかなく重複しやすい。補充をまたいでも直近 5 問と同じ数が出ないことを確認する
    func testRecentNumbersAreNotRepeated() {
        for difficulty in [Difficulty.easy, .normal] {
            for probability in [0.3, 0.7] {
                let manager = QuizDataManager(primeProbability: probability)
                var generator = SeededGenerator(seed: 11)
                var numbers: [Int] = []
                for _ in 0..<50 {
                    numbers += manager.makeQuizData(
                        difficulty: difficulty,
                        range: .oneOrTwoDigits,
                        questionCount: .five,
                        using: &generator
                    ).map(\.number)
                }
                for index in numbers.indices {
                    let recent = numbers[max(0, index - QuizDataManager.recentNumberWindow)..<index]
                    XCTAssertFalse(
                        recent.contains(numbers[index]),
                        "\(difficulty.rawValue) の \(index) 問目 \(numbers[index]) が直近 \(Array(recent)) と重複"
                    )
                }
            }
        }
    }

    /// Hard × 1-99 の素数でない数は 1・49・77・91 の 4 個しかなく、直近 5 問をすべて避けることはできない。
    /// その場合でも出題が止まらず、直前の数とは重ならないことを確認する
    func testRecentNumbersFallBackWhenCandidatesAreFewerThanWindow() {
        let manager = QuizDataManager(primeProbability: 0.3)
        var generator = SeededGenerator(seed: 12)
        var numbers: [Int] = []
        for _ in 0..<50 {
            numbers += manager.makeQuizData(
                difficulty: .hard,
                range: .oneOrTwoDigits,
                questionCount: .five,
                using: &generator
            ).map(\.number)
        }
        XCTAssertEqual(numbers.count, 250)
        for index in numbers.indices.dropFirst() {
            XCTAssertNotEqual(numbers[index], numbers[index - 1], "\(index) 問目が直前と同じ \(numbers[index])")
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
