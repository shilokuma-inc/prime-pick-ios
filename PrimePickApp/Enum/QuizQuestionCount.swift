//
//  QuizQuestionCount.swift
//  PrimePickApp
//

import Foundation

/// 1 プレイあたりの問題数
enum QuizQuestionCount: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twenty = 20

    /// 既定の問題数（従来の固定値と同じ 10 問）
    static let `default`: QuizQuestionCount = .ten

    var id: Int { rawValue }

    /// 実際の問題数
    var value: Int { rawValue }
}
