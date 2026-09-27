//
//  AnswerExplanationView.swift
//  PrimePickApp
//

import SwiftUI

/// 解答直後に短時間だけ表示する、出題された数のミニ解説（`17 は素数` / `91 = 7 × 13`）
struct AnswerExplanationView: View {
    let explanation: NumberExplanation

    var body: some View {
        explanation.text
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Capsule().fill(.ultraThinMaterial))
            .shadow(radius: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerExplanationView(explanation: NumberExplanation(number: 17))
        AnswerExplanationView(explanation: NumberExplanation(number: 91))
        AnswerExplanationView(explanation: NumberExplanation(number: 1))
    }
}
