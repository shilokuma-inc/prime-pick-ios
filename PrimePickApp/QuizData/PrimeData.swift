//
//  PrimeData.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import Foundation

final class PrimeData {
    init() {}
    
    public func generateOneOrTwoDigitPrimes() -> [Int] {
        var twoDigitPrimes = [Int]()
        outerLoop: for num in 3..<100 {
            for i in 2..<num {
                if num % i == 0 {
                    continue outerLoop
                }
            }
            twoDigitPrimes.append(num)
        }
        return twoDigitPrimes
    }
    
    public func generateThreeOrFourDigitPrimes() -> [Int] {
        var twoDigitPrimes = [Int]()
        outerLoop: for num in 100..<10000 {
            for i in 2..<num {
                if num % i == 0 {
                    continue outerLoop
                }
            }
            twoDigitPrimes.append(num)
        }
        return twoDigitPrimes
    }
    
    public func generateFiveOrSixDigitPrimes() -> [Int] {
        var twoDigitPrimes = [Int]()
        outerLoop: for num in 10000..<1000000 {
            for i in 2..<num {
                if num % i == 0 {
                    continue outerLoop
                }
            }
            twoDigitPrimes.append(num)
        }
        return twoDigitPrimes
    }
}
