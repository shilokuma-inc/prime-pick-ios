//
//  DailyChallengeGenerator.swift
//  PrimePickApp
//

import Foundation

/// デイリーチャレンジの 10 問を作る。同じ `dayKey` からは、どの端末・どの OS でも同じ 10 問ができる
///
/// 「全員が同じ問題」を守るため、版ごとに中身を凍結する（Discussion #181 本文 3 章）。
/// - 乱数は自前の `SplitMix64`。標準ライブラリの `random(in:using:)`・`randomElement(using:)`・`shuffled(using:)` は
///   OS の更新で引き方が変わりうるため使わない（`QuizDataManager`・`SeededGenerator`・GameplayKit にも依存しない）
/// - シードは `dayKey` の UTF-8 から FNV-1a で作る。`hashValue` / `Hasher` は起動ごとに値が変わるため使わない
/// - 出題を変えたくなったら既存の版は触らず、新しい版を足す。`DailyChallengeGeneratorTests` のゴールデンテストが変更を検出する
enum DailyChallengeGenerator: Int, CaseIterable {
    case v1 = 1

    /// 記録（`DailyChallengeRecord.generatorVersion`）に残す版の番号
    var version: Int { rawValue }

    /// `dayKey`（`2026-10-01` の形式）の日の 10 問
    func makeQuizData(dayKey: String) -> [QuizEntity] {
        switch self {
        case .v1:
            return DailyChallengeGeneratorV1.makeQuizData(dayKey: dayKey)
        }
    }
}

// MARK: - v1（凍結済み。中身を変えない）

/// v1 の出題
///
/// - 段階: 1〜3 問目は Easy × 1-99、4〜7 問目は Normal × 100-999、8〜10 問目は Hard × 100-999（2・3・5 の倍数を除く）
/// - 素数の出現確率はその日 1 回だけ 0.3〜0.7 から引き、各問題は独立にその確率で素数か合成数かを決める。10 問の中で帳尻は合わせない
/// - 同じ日の 10 問の中で同じ数は出さない
enum DailyChallengeGeneratorV1 {
    /// シードを作るときに `dayKey` の前に付ける文字列。版ごとに変え、別の版と同じ乱数列にならないようにする
    static let seedPrefix = "prime-pick.daily.v1:"
    /// 素数の出現確率を引く範囲（下限と幅）
    static let primeProbabilityLowerBound = 0.3
    static let primeProbabilityWidth = 0.4

    /// 1 段階分の出題条件
    struct Stage: Equatable {
        let questionCount: Int
        let difficulty: Difficulty
        let range: QuizRange
        let bounds: ClosedRange<Int>
        let excludesMultiplesOfTwoThreeFive: Bool
    }

    /// 段階の並び。`QuizRange.bounds` などの既存の値が将来変わっても v1 の出題が変わらないよう、範囲はここに直接書く
    static let stages: [Stage] = [
        Stage(questionCount: 3, difficulty: .easy, range: .oneOrTwoDigits, bounds: 1...99, excludesMultiplesOfTwoThreeFive: false),
        Stage(questionCount: 4, difficulty: .normal, range: .threeDigits, bounds: 100...999, excludesMultiplesOfTwoThreeFive: false),
        Stage(questionCount: 3, difficulty: .hard, range: .threeDigits, bounds: 100...999, excludesMultiplesOfTwoThreeFive: true)
    ]

    static func makeQuizData(dayKey: String) -> [QuizEntity] {
        var generator = SplitMix64(seed: seed(dayKey: dayKey))
        let primeProbability = primeProbabilityLowerBound + primeProbabilityWidth * generator.nextUnit()

        var usedNumbers = Set<Int>()
        var quizData: [QuizEntity] = []
        for stage in stages {
            let candidates = Candidates(stage: stage)
            for _ in 0..<stage.questionCount {
                let wantsPrime = generator.nextUnit() < primeProbability
                let preferred = (wantsPrime ? candidates.primes : candidates.nonPrimes).filter { !usedNumbers.contains($0) }
                // 指定した側を使い切ることは v1 の段階では起きないが、起きても出題が止まらないよう反対側から引く
                let pool = preferred.isEmpty
                    ? (wantsPrime ? candidates.nonPrimes : candidates.primes).filter { !usedNumbers.contains($0) }
                    : preferred
                let number = pool[generator.nextIndex(below: pool.count)]
                usedNumbers.insert(number)
                quizData.append(
                    QuizEntity(
                        quizId: quizData.count + 1,
                        number: number,
                        isCorrect: PrimeFactorization.isPrime(number),
                        difficulty: stage.difficulty,
                        range: stage.range
                    )
                )
            }
        }
        return quizData
    }

    /// `seedPrefix + dayKey` の UTF-8 に対する FNV-1a（64bit）
    static func seed(dayKey: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in (seedPrefix + dayKey).utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    /// 段階の範囲の数を、小さい順に素数と素数でない数（1 を含む）に分けたもの
    private struct Candidates {
        let primes: [Int]
        let nonPrimes: [Int]

        init(stage: Stage) {
            var primes: [Int] = []
            var nonPrimes: [Int] = []
            for number in stage.bounds {
                if stage.excludesMultiplesOfTwoThreeFive, number % 2 == 0 || number % 3 == 0 || number % 5 == 0 {
                    continue
                }
                if PrimeFactorization.isPrime(number) {
                    primes.append(number)
                } else {
                    nonPrimes.append(number)
                }
            }
            self.primes = primes
            self.nonPrimes = nonPrimes
        }
    }
}

// MARK: - 乱数

/// SplitMix64（Steele, Lea, Flood 2014）。状態 64bit の小さな PRNG で、同じシードからは常に同じ列を返す
///
/// デイリーの出題を凍結するために自前で持つ。`RandomNumberGenerator` には適合させない
/// （適合させると標準ライブラリの `random(in:using:)` などに渡せてしまい、引き方が OS に依存する）。
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    /// `0..<1` の一様な小数。上位 53bit をそのまま `Double` の仮数にする
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * 0x1p-53
    }

    /// `0..<upperBound` から偏りなく 1 つ選ぶ
    ///
    /// 単純な剰余は `2^64` が `upperBound` で割り切れない分だけ小さい値に偏るため、
    /// 端数にあたる `2^64 mod upperBound` 個の値を捨てて引き直す。
    mutating func nextIndex(below upperBound: Int) -> Int {
        precondition(upperBound > 0, "upperBound は 1 以上")
        let bound = UInt64(upperBound)
        let threshold = (0 &- bound) % bound
        while true {
            let value = next()
            if value >= threshold {
                return Int(value % bound)
            }
        }
    }
}
