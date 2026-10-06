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
                .foregroundStyle(Color.quizSubText)

            Spacer()

            if isComboVisible {
                Text("Combo \(currentCombo)")
                    .font(.custom("ArialRoundedMTBold", size: 28))
                    .foregroundStyle(Color.quizComboText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, quizIndexVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `No.` の段の上下に足す余白
///
/// この段の高さは `No.`（45pt のフォント。1 行の高さは約 52pt）の固有の高さ + この余白で決まり、約 60pt になる。
/// 以前は出題領域の 1/6（iPhone SE で約 50pt、16 Pro Max で約 68pt）を割り当てていたが、
/// 文字 1 行ぶんに縮めて、残りを数字カードの段に回している（Discussion #216 の案 C）
private let quizIndexVerticalPadding: CGFloat = 4

#Preview {
    QuizIndexView(difficulty: .easy, quizNumber: .constant(2), currentCombo: 3)
}
