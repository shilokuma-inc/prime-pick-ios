//
//  PrimeData.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import Foundation

final class PrimeData {
    func generateOneOrTwoDigitPrimes() -> [Int] {
        var twoDigitPrimes = [Int]()
        outerLoop: for num in 1..<100 {
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
