//
//  QuizIndexView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizIndexView: View {
    let difficulty: String
    @Binding var quizNumber: Int
    
    var body: some View {
        ZStack(alignment: .leading) {
            if difficulty == "Easy" {
                Color("appGreen")
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            } else if difficulty == "Normal" {
                Color.blue
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            } else if difficulty == "Hard" {
                Color.red
                    .opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
            }
            
            Text("No.\(quizNumber + 1)")
                .font(.custom("ArialRoundedMTBold", size: 45))
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 16)
        }
    }
}
