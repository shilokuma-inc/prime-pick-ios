//
//  QuizTimeLimitView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/21.
//

import SwiftUI

struct QuizTimeLimitView: View {
    let difficulty: String
    @State private var progress: Double = 0.01
    
    var body: some View {
        ZStack {
            if difficulty == "Easy" {
                Color.appGreen
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
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.horizontal, 20)
            
            ZStack {
                Text("No Timelimit!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .offset(x: 1, y: 1)
                
                Text("No Timelimit!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .offset(x: 1, y: -1)
                
                Text("No Timelimit!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .offset(x: -1, y: 1)
                
                Text("No Timelimit!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .offset(x: -1, y: -1)

                Text("No Timelimit!")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
            }
            .padding()
            
        }
    }
}

#Preview {
    QuizTimeLimitView(difficulty: "Easy")
}
