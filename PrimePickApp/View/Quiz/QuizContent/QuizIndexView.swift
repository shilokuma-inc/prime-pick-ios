//
//  QuizIndexView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizIndexView: View {
    let difficulty: Difficulty
    @Binding var quizNumber: Int
    let currentCombo: Int

    /// コンボが 2 以上のときだけ表示する（1 連続目は倍率が 1.0 倍で意味がないため）
    private var isComboVisible: Bool {
        currentCombo >= 2
    }

    var body: some View {
        HStack {
            Text("No.\(quizNumber + 1)")
                .font(.custom("ArialRoundedMTBold", size: 45))
                .foregroundStyle(Color.gray)

            Spacer()

            if isComboVisible {
                Text("Combo \(currentCombo)")
                    .font(.custom("ArialRoundedMTBold", size: 28))
                    .foregroundStyle(Color.orange)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    QuizIndexView(difficulty: .easy, quizNumber: .constant(2), currentCombo: 3)
}
