//
//  QuizIndexView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/22.
//

import SwiftUI

struct QuizIndexView: View {
    @Binding var quizNumber: Int
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color("appGreen")
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            Text("No.\(quizNumber + 1)")
                .font(.custom("ArialRoundedMTBold", size: 45))
                .foregroundStyle(Color.gray)
                .padding(.horizontal, 16)
        }
    }
}
