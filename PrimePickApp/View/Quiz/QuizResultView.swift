//
//  QuizResultView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizResultView: View {
    @Environment(\.dismiss) private var dismiss
    let score: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.green
                    .frame(
                        width: geometry.size.width * 2 / 3,
                        height: geometry.size.height / 2
                    )
                
                Text("Your Score is \(score) points!")
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    QuizResultView(score: 1)
}
