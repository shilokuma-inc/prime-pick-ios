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
    
    var body: some View {
        ZStack {
            quizNumberBackgroundView(difficulty: difficulty)
            
            quizNumberText(
                quizNumber: quizNumber,
                difficulty: difficulty,
                quizData: quizData
            )
        }
    }
}

private func quizNumberBackgroundView(difficulty: Difficulty) -> some View {
    let color = if difficulty == .easy {
        Color.appGreen
    } else if difficulty == .normal {
        Color.blue
    } else {
        Color.red
    }
    
    return RoundedRectangle(cornerRadius: 25)
        .stroke(color, lineWidth: 5)
        .frame(width: 300, height: 200)
        .shadow(radius: 10)
        .background(
            RoundedRectangle(cornerRadius: 25).fill(Color.white)
        )
}

/// 枠（幅 300）に収まる余白を引いた、数字の描画に使える横幅
private let quizNumberContentWidth: CGFloat = 260

private func quizNumberText(quizNumber: Int, difficulty: Difficulty, quizData: [QuizEntity]) -> some View {
    let text = quizData[quizNumber].number.description

    return Text(text)
        .font(.custom("ArialRoundedMTBold", size: quizNumberFontSize(digitCount: text.count)))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .foregroundStyle(Color.gray)
        .frame(width: quizNumberContentWidth)
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
