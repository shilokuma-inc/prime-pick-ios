//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import GameplayKit

class QuizDataManager {
    func makeQuizData(
        difficulty: Difficulty,
        range: QuizRange,
        questionCount: QuizQuestionCount
    ) -> [QuizEntity] {
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        var generator = SeededGenerator(seed: timestamp)
        return makeQuizData(
            difficulty: difficulty,
            range: range,
            questionCount: questionCount,
            using: &generator
        )
    }

    /// 乱数生成器を差し替えられる版。
    /// テストから決まった出題を作るために分けている。
    func makeQuizData<Generator: RandomNumberGenerator>(
        difficulty: Difficulty,
        range: QuizRange,
        questionCount: QuizQuestionCount,
        using generator: inout Generator
    ) -> [QuizEntity] {
        var quizData: [QuizEntity] = []
        quizData.reserveCapacity(questionCount.value)

        for quizId in 1...questionCount.value {
            let number = randomNumber(in: range.bounds, difficulty: difficulty, using: &generator)
            quizData.append(
                QuizEntity(quizId: quizId, number: number, isCorrect: PrimeFactorization.isPrime(number))
            )
        }
        return quizData
    }

    /// 出題する数を 1 つ引く。
    ///
    /// Hard では 2・3・5 の倍数を出題しないが、引いてから捨てる方式だと約 73% が無駄引きになるうえ、
    /// 試行回数に上限がない。`CoprimeToThirty` で候補の通し番号を直接引くことで 1 回の抽選で決める。
    private func randomNumber<Generator: RandomNumberGenerator>(
        in bounds: ClosedRange<Int>,
        difficulty: Difficulty,
        using generator: inout Generator
    ) -> Int {
        guard difficulty.excludesMultiplesOfTwoThreeFive else {
            return Int.random(in: bounds, using: &generator)
        }
        // 候補が 1 つもないレンジは現状ないが、将来追加されても出題が止まらないようにフォールバックする
        return CoprimeToThirty.randomValue(in: bounds, using: &generator)
            ?? Int.random(in: bounds, using: &generator)
    }
}

/// 2・3・5 のいずれでも割り切れない数（＝ 30 と互いに素な数）を扱う。
///
/// 30 で割った余りが {1, 7, 11, 13, 17, 19, 23, 29} の 8 通りのときだけ 2・3・5 で割り切れず、
/// この並びは 30 ごとにそのまま繰り返される。
/// この規則性があるので「小さい順に数えて何番目か」と「実際の数」を直接行き来でき、
/// 引き直しなしで候補だけを一様に抽選できる。
enum CoprimeToThirty {
    /// 2・3・5 のどれでも割り切れない、30 で割った余り
    static let residues = [1, 7, 11, 13, 17, 19, 23, 29]

    /// 並びが繰り返される周期
    static let cycle = 30

    /// `1...upperBound` に含まれる候補の個数
    static func count(upTo upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        let (cycles, remainder) = upperBound.quotientAndRemainder(dividingBy: cycle)
        return cycles * residues.count + residues.filter { $0 <= remainder }.count
    }

    /// 小さい順に数えて `index` 番目（0 始まり）の候補
    static func value(at index: Int) -> Int {
        let (cycles, position) = index.quotientAndRemainder(dividingBy: residues.count)
        return cycles * cycle + residues[position]
    }

    /// `bounds` に含まれる候補から一様に 1 つ選ぶ。候補が 1 つもなければ `nil`
    static func randomValue<Generator: RandomNumberGenerator>(
        in bounds: ClosedRange<Int>,
        using generator: inout Generator
    ) -> Int? {
        let countBelowRange = count(upTo: bounds.lowerBound - 1)
        let countInRange = count(upTo: bounds.upperBound) - countBelowRange
        guard countInRange > 0 else { return nil }
        return value(at: countBelowRange + Int.random(in: 0..<countInRange, using: &generator))
    }
}

/// シード値から決まった乱数列を作る `RandomNumberGenerator`。
///
/// `GKMersenneTwisterRandomSource` が一度に返すのは 32bit 分なので、2 回引いて 64bit に組み立てる。
/// 以前は `nextUniform()` の戻り値（`Float`）に `Float(UInt64.max)` を掛けていたが、
/// - `Float` の仮数部は 24bit しかなく、下位 40bit 前後が常に 0 になる
/// - `Float(UInt64.max)` は 2^64 に丸まるため、`nextUniform()` が 1.0 を返すと積が
///   `UInt64` の範囲を超えてクラッシュする（実測で約 428 万回に 1 回発生）
/// という問題があったため、整数のまま扱っている。
struct SeededGenerator: RandomNumberGenerator {
    private let source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        source = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let high = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        let low = UInt64(UInt32(bitPattern: Int32(truncatingIfNeeded: source.nextInt())))
        return high << 32 | low
    }
}
