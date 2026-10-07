//
//  QuizDataManager.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation
import GameplayKit

/// 1 プレイ分の出題を作る。
///
/// 素数が出る確率 `primeProbability` はプレイ開始時に 0.3〜0.7 から隠れて決め、各問題は独立にその確率で素数を出す。
/// 「10 問ごとに 4〜6 問」のような枠内の帳尻合わせをすると、序盤の偏りから残りの答えを読めてしまうため、
/// 枠や残数による補正はあえてしない。
/// タイムアタックの問題補充でも同じ確率を使い続けられるよう、1 プレイにつき 1 インスタンスを使い回す。
final class QuizDataManager {
    /// 素数の出現確率を引く範囲
    static let primeProbabilityRange: ClosedRange<Double> = 0.3...0.7
    /// 同じ数を続けて出さないために覚えておく直近の問題数
    static let recentNumberWindow: Int = 5

    /// このプレイで素数が出る確率
    let primeProbability: Double
    /// 直近に出題した数（古い順）。補充をまたいでも重複を避けられるよう、呼び出しをまたいで保持する
    private var recentNumbers: [Int] = []
    /// 難易度・レンジごとの候補。Hard × 4 桁でも 1 プレイ 1 回の計算で済むよう使い回す
    private var candidatePoolCache: [CandidatePoolKey: CandidatePool] = [:]

    init(primeProbability: Double) {
        self.primeProbability = primeProbability
    }

    /// 素数の出現確率を `primeProbabilityRange` から引いて作る
    convenience init<Generator: RandomNumberGenerator>(using generator: inout Generator) {
        self.init(primeProbability: Double.random(in: Self.primeProbabilityRange, using: &generator))
    }

    convenience init() {
        var generator = SystemRandomNumberGenerator()
        self.init(using: &generator)
    }

    func makeQuizData(
        difficulty: Difficulty,
        range: QuizRange,
        questionCount: QuizQuestionCount
    ) -> [QuizEntity] {
        // 撮影モードでは撮り直しても同じ出題になるようシードを固定する
        let seed = ScreenshotDemo.isEnabled
            ? ScreenshotDemo.randomSeed
            : UInt64(Date().timeIntervalSince1970 * 1000)
        var generator = SeededGenerator(seed: seed)
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
        let pool = candidatePool(difficulty: difficulty, range: range)
        var quizData: [QuizEntity] = []
        quizData.reserveCapacity(questionCount.value)

        for quizId in 1...questionCount.value {
            let wantsPrime = Double.random(in: 0..<1, using: &generator) < primeProbability
            let number = drawNumber(from: pool, wantsPrime: wantsPrime, using: &generator)
            quizData.append(
                QuizEntity(quizId: quizId, number: number, isCorrect: PrimeFactorization.isPrime(number))
            )
        }
        return quizData
    }

    /// 素数・合成数のどちらかを決めたうえで、直近に出した数を避けて 1 つ引く。
    ///
    /// 指定した側の候補が無いレンジは現状ないが、将来追加されても出題が止まらないよう反対側にフォールバックし、
    /// それでも無ければ 2・3・5 の除外をあきらめてレンジ全体から引く。
    private func drawNumber<Generator: RandomNumberGenerator>(
        from pool: CandidatePool,
        wantsPrime: Bool,
        using generator: inout Generator
    ) -> Int {
        let preferred = wantsPrime ? pool.primes : pool.nonPrimes
        let candidates = preferred.isEmpty ? (wantsPrime ? pool.nonPrimes : pool.primes) : preferred
        let number = freshCandidates(in: candidates).randomElement(using: &generator)
            ?? Int.random(in: pool.bounds, using: &generator)

        recentNumbers.append(number)
        if recentNumbers.count > Self.recentNumberWindow {
            recentNumbers.removeFirst(recentNumbers.count - Self.recentNumberWindow)
        }
        return number
    }

    /// 直近に出した数を除いた候補。
    ///
    /// Hard × 1-99 の素数でない数（1・49・77・91）のように候補が覚えておく問題数以下だと、すべて除くと空になる。
    /// その場合は古いものから順に除外をあきらめ、少なくとも直前の数とはなるべく重ならないようにする。
    private func freshCandidates(in candidates: [Int]) -> [Int] {
        for window in stride(from: recentNumbers.count, to: 0, by: -1) {
            let recent = Set(recentNumbers.suffix(window))
            let fresh = candidates.filter { !recent.contains($0) }
            if !fresh.isEmpty { return fresh }
        }
        return candidates
    }

    private func candidatePool(difficulty: Difficulty, range: QuizRange) -> CandidatePool {
        let key = CandidatePoolKey(excludesMultiplesOfTwoThreeFive: difficulty.excludesMultiplesOfTwoThreeFive, range: range)
        if let cached = candidatePoolCache[key] { return cached }
        let pool = CandidatePool(
            bounds: range.bounds,
            excludesMultiplesOfTwoThreeFive: key.excludesMultiplesOfTwoThreeFive
        )
        candidatePoolCache[key] = pool
        return pool
    }
}

private struct CandidatePoolKey: Hashable {
    let excludesMultiplesOfTwoThreeFive: Bool
    let range: QuizRange
}

/// 出題しうる数を素数と素数でない数（1 を含む）に分けたもの
private struct CandidatePool {
    let bounds: ClosedRange<Int>
    let primes: [Int]
    let nonPrimes: [Int]

    /// Hard では 2・3・5 の倍数を候補に入れない。
    /// 2・3・5 自身も倍数なので素数側から外れ、1 は素数でない側に残る
    init(bounds: ClosedRange<Int>, excludesMultiplesOfTwoThreeFive: Bool) {
        let numbers: [Int]
        if excludesMultiplesOfTwoThreeFive {
            let start = CoprimeToThirty.count(upTo: bounds.lowerBound - 1)
            let end = CoprimeToThirty.count(upTo: bounds.upperBound)
            numbers = (start..<end).map(CoprimeToThirty.value(at:))
        } else {
            numbers = Array(bounds)
        }
        var primes: [Int] = []
        var nonPrimes: [Int] = []
        for number in numbers {
            if PrimeFactorization.isPrime(number) {
                primes.append(number)
            } else {
                nonPrimes.append(number)
            }
        }
        self.bounds = bounds
        self.primes = primes
        self.nonPrimes = nonPrimes
    }
}

/// 2・3・5 のいずれでも割り切れない数（＝ 30 と互いに素な数）を扱う。
///
/// 30 で割った余りが {1, 7, 11, 13, 17, 19, 23, 29} の 8 通りのときだけ 2・3・5 で割り切れず、
/// この並びは 30 ごとにそのまま繰り返される。
/// この規則性があるので「小さい順に数えて何番目か」と「実際の数」を直接行き来でき、
/// 1 から順に割り算で確かめなくても候補だけを列挙できる。
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
