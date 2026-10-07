//
//  DailyChallengeGeneratorTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class DailyChallengeGeneratorTests: XCTestCase {

    // MARK: - ゴールデンテスト（v1 の凍結）

    /// v1 が出した 10 問をそのまま書いたもの。
    ///
    /// **期待値を書き換えて通してはいけない。** 落ちたら「全員が同じ問題」が壊れている（同じ日に端末やバージョンで問題が変わる）。
    /// 生成器 v1 の変更を戻すこと。出題を変えたいなら v2 を足す。
    private let goldenV1: [String: [Int]] = [
        "2026-10-01": [77, 38, 61, 131, 464, 943, 880, 169, 299, 383],
        "2026-10-02": [7, 71, 16, 577, 200, 307, 743, 989, 233, 593],
        "2026-10-31": [23, 71, 32, 244, 185, 944, 761, 481, 913, 259],
        "2026-12-31": [3, 8, 89, 463, 617, 251, 352, 913, 289, 793],
        "2027-01-01": [51, 66, 73, 211, 706, 257, 566, 731, 463, 253],
        "2028-02-29": [61, 8, 32, 521, 970, 563, 263, 107, 269, 317]
    ]

    func testV1MatchesGoldenQuizData() {
        for (dayKey, numbers) in goldenV1 {
            XCTAssertEqual(DailyChallengeGenerator.v1.makeQuizData(dayKey: dayKey).map(\.number), numbers, dayKey)
        }
    }

    func testV1VersionNumberIsOne() {
        XCTAssertEqual(DailyChallengeGenerator.v1.version, 1)
    }

    // MARK: - 出題の形

    /// 1〜3 問目は Easy × 1-99、4〜7 問目は Normal × 100-999、8〜10 問目は Hard × 100-999（2・3・5 の倍数を除く）
    func testV1FollowsStages() {
        for dayKey in sampleDayKeys {
            let quizData = DailyChallengeGenerator.v1.makeQuizData(dayKey: dayKey)
            XCTAssertEqual(quizData.count, 10, dayKey)
            XCTAssertEqual(quizData.map(\.quizId), Array(1...10), dayKey)
            XCTAssertEqual(
                quizData.map(\.difficulty),
                [.easy, .easy, .easy, .normal, .normal, .normal, .normal, .hard, .hard, .hard],
                dayKey
            )
            for quiz in quizData.prefix(3) {
                XCTAssertTrue((1...99).contains(quiz.number), "\(dayKey): \(quiz.number)")
                XCTAssertEqual(quiz.range, .oneOrTwoDigits)
            }
            for quiz in quizData.dropFirst(3) {
                XCTAssertTrue((100...999).contains(quiz.number), "\(dayKey): \(quiz.number)")
                XCTAssertEqual(quiz.range, .threeDigits)
            }
            for quiz in quizData.suffix(3) {
                XCTAssertFalse(
                    quiz.number % 2 == 0 || quiz.number % 3 == 0 || quiz.number % 5 == 0,
                    "\(dayKey): \(quiz.number) は Hard に出ない"
                )
            }
            for quiz in quizData {
                XCTAssertEqual(quiz.isCorrect, PrimeFactorization.isPrime(quiz.number), "\(dayKey): \(quiz.number)")
            }
        }
    }

    func testV1DoesNotRepeatNumbersWithinADay() {
        for dayKey in sampleDayKeys {
            let numbers = DailyChallengeGenerator.v1.makeQuizData(dayKey: dayKey).map(\.number)
            XCTAssertEqual(Set(numbers).count, numbers.count, dayKey)
        }
    }

    func testV1IsDeterministicAndDiffersByDay() {
        XCTAssertEqual(
            DailyChallengeGenerator.v1.makeQuizData(dayKey: "2026-10-01").map(\.number),
            DailyChallengeGenerator.v1.makeQuizData(dayKey: "2026-10-01").map(\.number)
        )
        let distinct = Set(sampleDayKeys.map { DailyChallengeGenerator.v1.makeQuizData(dayKey: $0).map(\.number) })
        XCTAssertEqual(distinct.count, sampleDayKeys.count)
    }

    /// 1 年分（各月 1〜28 日）で素数がおおむね半分になること（日ごとの確率は 0.3〜0.7 で、日ごとのばらつきは許す）
    func testV1PrimeShareOverAYearIsAroundHalf() {
        var primeCount = 0
        var total = 0
        for month in 1...12 {
            for day in 1...28 {
                let dayKey = String(format: "2027-%02d-%02d", month, day)
                let quizData = DailyChallengeGenerator.v1.makeQuizData(dayKey: dayKey)
                primeCount += quizData.filter(\.isCorrect).count
                total += quizData.count
            }
        }
        let share = Double(primeCount) / Double(total)
        XCTAssertTrue((0.4...0.6).contains(share), "素数の割合 \(share)")
    }

    // MARK: - シード

    func testSeedIsFNV1aOfPrefixedDayKey() {
        XCTAssertEqual(DailyChallengeGeneratorV1.seedPrefix, "prime-pick.daily.v1:")
        XCTAssertNotEqual(
            DailyChallengeGeneratorV1.seed(dayKey: "2026-10-01"),
            DailyChallengeGeneratorV1.seed(dayKey: "2026-10-02")
        )
        XCTAssertEqual(DailyChallengeGeneratorV1.seed(dayKey: "2026-10-01"), DailyChallengeGeneratorV1.seed(dayKey: "2026-10-01"))
    }

    // MARK: - SplitMix64

    /// 参照実装（Vigna の splitmix64.c）の既知の出力列
    func testSplitMix64MatchesReferenceOutput() {
        var generator = SplitMix64(seed: 1_234_567)
        XCTAssertEqual(
            (0..<5).map { _ in generator.next() },
            [6_457_827_717_110_365_317, 3_203_168_211_198_807_973, 9_817_491_932_198_370_423,
             4_593_380_528_125_082_431, 16_408_922_859_458_223_821]
        )
        var zero = SplitMix64(seed: 0)
        XCTAssertEqual(zero.next(), 0xe220_a839_7b1d_cdaf)
    }

    func testNextUnitIsInHalfOpenUnitInterval() {
        var generator = SplitMix64(seed: 42)
        for _ in 0..<10_000 {
            let value = generator.nextUnit()
            XCTAssertTrue(value >= 0 && value < 1, "\(value)")
        }
    }

    func testNextIndexStaysBelowUpperBoundAndCoversAllValues() {
        var generator = SplitMix64(seed: 7)
        var seen = Set<Int>()
        for _ in 0..<1_000 {
            let index = generator.nextIndex(below: 7)
            XCTAssertTrue((0..<7).contains(index))
            seen.insert(index)
        }
        XCTAssertEqual(seen, Set(0..<7))
        XCTAssertEqual(generator.nextIndex(below: 1), 0)
    }

    private let sampleDayKeys = [
        "2026-10-01", "2026-10-02", "2026-10-31", "2026-12-31", "2027-01-01", "2028-02-29", "2030-06-15"
    ]
}
