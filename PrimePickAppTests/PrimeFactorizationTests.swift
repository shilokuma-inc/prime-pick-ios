//
//  PrimeFactorizationTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class PrimeFactorizationTests: XCTestCase {

    // MARK: - 素数判定

    func testIsPrimeForSmallNumbers() {
        XCTAssertFalse(PrimeFactorization.isPrime(0))
        XCTAssertFalse(PrimeFactorization.isPrime(1))
        XCTAssertTrue(PrimeFactorization.isPrime(2))
        XCTAssertTrue(PrimeFactorization.isPrime(3))
        XCTAssertFalse(PrimeFactorization.isPrime(4))
        XCTAssertTrue(PrimeFactorization.isPrime(97))
        XCTAssertFalse(PrimeFactorization.isPrime(91))  // 7 * 13
    }

    func testIsPrimeForNegativeNumbers() {
        XCTAssertFalse(PrimeFactorization.isPrime(-1))
        XCTAssertFalse(PrimeFactorization.isPrime(-7))
        XCTAssertFalse(PrimeFactorization.isPrime(Int.min))
    }

    /// エラトステネスのふるいと全件突き合わせる。
    /// ミラー・ラビンは基数の選び方を誤ると特定の数だけ落ちるため、範囲での総当たりで担保する。
    func testIsPrimeMatchesSieveOfEratosthenes() {
        let limit = 50_000
        var sieve = [Bool](repeating: true, count: limit + 1)
        sieve[0] = false
        sieve[1] = false
        var factor = 2
        while factor * factor <= limit {
            if sieve[factor] {
                var multiple = factor * factor
                while multiple <= limit {
                    sieve[multiple] = false
                    multiple += factor
                }
            }
            factor += 1
        }

        for number in 0...limit where PrimeFactorization.isPrime(number) != sieve[number] {
            XCTFail("\(number) の判定がふるいと一致しない")
            return
        }
    }

    /// 擬素数はフェルマーテストをすり抜けるので、合成数と判定できることを確認する
    func testIsPrimeRejectsCarmichaelNumbers() {
        for number in [561, 1105, 1729, 2465, 2821, 6601, 8911, 41041, 825_265, 321_197_185] {
            XCTAssertFalse(PrimeFactorization.isPrime(number), "\(number) は合成数")
        }
    }

    /// 試し割りでは現実的な時間で終わらない大きさでも正しく判定できること
    func testIsPrimeForLargeNumbers() {
        XCTAssertTrue(PrimeFactorization.isPrime(2_147_483_647))            // 2^31 - 1
        XCTAssertTrue(PrimeFactorization.isPrime(999_999_999_989))
        XCTAssertTrue(PrimeFactorization.isPrime(2_305_843_009_213_693_951)) // 2^61 - 1

        XCTAssertFalse(PrimeFactorization.isPrime(4_294_967_297))            // 641 * 6700417
        XCTAssertFalse(PrimeFactorization.isPrime(1_000_000_007 * 1_000_000_009))
        XCTAssertFalse(PrimeFactorization.isPrime(Int.max))                  // 7^2 * 73 * 127 * ...
    }

    // MARK: - 素因数分解

    func testFactors() {
        XCTAssertEqual(PrimeFactorization.factors(of: 391), [17, 23])
        XCTAssertEqual(PrimeFactorization.factors(of: 8), [2, 2, 2])
        XCTAssertEqual(PrimeFactorization.factors(of: 397), [397])
        XCTAssertEqual(PrimeFactorization.factors(of: 1), [])
        XCTAssertEqual(PrimeFactorization.factors(of: 0), [])
        XCTAssertEqual(PrimeFactorization.factors(of: -6), [])
    }

    /// 素因数の総積が元の数に戻ること、素数なら自分自身だけになることを範囲で確認する
    func testFactorsAgreeWithIsPrime() {
        for number in 2...5_000 {
            let factors = PrimeFactorization.factors(of: number)
            XCTAssertEqual(factors.reduce(1, *), number, "\(number) の素因数の積が元に戻らない")
            XCTAssertEqual(factors == [number], PrimeFactorization.isPrime(number), "\(number)")
        }
    }
}
