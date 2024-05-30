//
//  QuizContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizContentView: View {
    let difficulty: Difficulty
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                QuizTimeLimitView(difficulty: difficulty)
                    .frame(height: geometry.size.height)
            }
        }
    }
}

#Preview {
    QuizContentView(difficulty: .easy)
}
