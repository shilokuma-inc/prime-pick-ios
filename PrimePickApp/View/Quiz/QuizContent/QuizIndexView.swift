//
//  QuizIndexView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizIndexView: View {
    let difficulty: Difficulty
    var gameMode: GameMode = .practice
    @Binding var quizNumber: Int
    let currentCombo: Int
    /// 現在の合計スコア。タイムアタックでだけ表示する
    var score: Int = 0

    /// コンボが 2 以上のときだけ表示する（1 連続目は倍率が 1.0 倍で意味がないため）
    private var isComboVisible: Bool {
        currentCombo >= 2
    }
    
    var body: some View {
        HStack {
            leadingLabel
                .font(.custom("ArialRoundedMTBold", size: 45))
                .foregroundStyle(Color.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            if isComboVisible {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Combo \(currentCombo)")
                        .font(.custom("ArialRoundedMTBold", size: 28))

                    // 倍率の数字は言語によらず同じ表記なので、ローカライズしない
                    if gameMode.isTimeAttack {
                        Text(verbatim: Self.multiplierText(combo: currentCombo))
                            .font(.custom("ArialRoundedMTBold", size: 22))
                    }
                }
                .foregroundStyle(Color.orange)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 左上の表示。タイムアタックは問題数に上限がなく「何問目か」より点数の方が意味を持つため、スコアに置き換える
    @ViewBuilder
    private var leadingLabel: some View {
        if gameMode.isTimeAttack {
            Text(verbatim: "\(score)")
                .contentTransition(.numericText(value: Double(score)))
                .animation(.snappy, value: score)
                .accessibilityLabel(Text("Score \(score)"))
        } else {
            Text("No.\(quizNumber + 1)")
        }
    }

    /// コンボ倍率の表示文言（例: `×1.6`）
    static func multiplierText(combo: Int) -> String {
        String(format: "×%.1f", ScoreCalculator.comboMultiplier(combo: combo))
    }
}

#Preview("練習") {
    QuizIndexView(difficulty: .easy, quizNumber: .constant(2), currentCombo: 3)
}

#Preview("タイムアタック") {
    QuizIndexView(
        difficulty: .easy,
        gameMode: .timeAttack(.thirtySeconds),
        quizNumber: .constant(2),
        currentCombo: 7,
        score: 1_245
    )
}
