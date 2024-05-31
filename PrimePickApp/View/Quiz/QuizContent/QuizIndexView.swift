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
    
    var body: some View {
        Text("No.\(quizNumber + 1)")
            .font(.custom("ArialRoundedMTBold", size: 45))
            .foregroundStyle(Color.gray)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
