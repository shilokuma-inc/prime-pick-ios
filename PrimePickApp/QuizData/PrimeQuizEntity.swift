//
//  PrimeQuizEntity.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/16.
//

import Foundation

struct PrimeQuizEntity {
    var quizId: Int
    var number: Int
    var isCorrect: Bool
    
    init(quizId: Int, number: Int, isCorrect: Bool) {
        self.quizId = quizId
        self.number = number
        self.isCorrect = isCorrect
    }
}
