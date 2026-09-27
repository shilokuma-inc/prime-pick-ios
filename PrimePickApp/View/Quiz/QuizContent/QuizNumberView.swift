//
//  QuizNumberView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/17.
//

import SwiftUI

struct QuizNumberView: View {
    @Binding var quizNumber: Int
    let difficulty: Difficulty
    let quizData: [QuizEntity]
    /// Great 段階以上では数字カードの枠を光らせる
    var comboStage: ComboStage = .normal
    
    var body: some View {
        GeometryReader { geometry in
            // 小さい画面でも設問文と数字カードが上下のビューにはみ出さないよう、カードの高さを縮める
            let cardHeight = max(0, min(quizNumberCardMaxHeight, geometry.size.height - quizQuestionAreaHeight))

            VStack(spacing: .zero) {
                // 何を答えるボタンなのかが分かるよう、設問文を常に表示する
                Text("Is it prime?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: quizQuestionAreaHeight)

                ZStack {
                    quizNumberBackgroundView(difficulty: difficulty, height: cardHeight)
                        .shadow(color: Color.orange.opacity(comboStage >= .great ? 0.9 : 0), radius: 16)
                        .animation(.easeInOut(duration: 0.3), value: comboStage)

                    quizNumberText(
                        quizNumber: quizNumber,
                        difficulty: difficulty,
                        quizData: quizData,
                        height: cardHeight
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// 設問文に割り当てる高さ
private let quizQuestionAreaHeight: CGFloat = 44

/// 数字カードの高さの上限
private let quizNumberCardMaxHeight: CGFloat = 200

private func quizNumberBackgroundView(difficulty: Difficulty, height: CGFloat) -> some View {
    let color = if difficulty == .easy {
        Color.appGreen
    } else if difficulty == .normal {
        Color.blue
    } else {
        Color.red
    }
    
    return RoundedRectangle(cornerRadius: 25)
        .stroke(color, lineWidth: 5)
        .frame(width: 300, height: height)
        .shadow(radius: 10)
        .background(
            RoundedRectangle(cornerRadius: 25).fill(Color.white)
        )
}

/// 枠（幅 300）に収まる余白を引いた、数字の描画に使える横幅
private let quizNumberContentWidth: CGFloat = 260

private func quizNumberText(quizNumber: Int, difficulty: Difficulty, quizData: [QuizEntity], height: CGFloat) -> some View {
    let text = quizData[quizNumber].number.description

    return Text(text)
        .font(.custom("ArialRoundedMTBold", size: quizNumberFontSize(digitCount: text.count)))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundStyle(Color.gray)
        .frame(width: quizNumberContentWidth, height: height)
}

/// 桁数に応じた文字サイズ
///
/// 難易度ではなく実際の桁数から決めることで、同じ難易度でもレンジが変われば追従する。
private func quizNumberFontSize(digitCount: Int) -> CGFloat {
    switch digitCount {
    case ...2:
        return 180
    case 3:
        return 130
    default:
        return 100
    }
}

struct QuizNumberView_Previews: PreviewProvider {
    @State static var quizNumber = 3
    
    static var previews: some View {
        QuizNumberView(
            quizNumber: $quizNumber,
            difficulty: .easy,
            quizData: [QuizEntity(quizId: 0, number: 3, isCorrect: true)]
        )
    }
}
