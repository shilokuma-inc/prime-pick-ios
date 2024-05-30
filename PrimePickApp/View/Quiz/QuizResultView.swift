//
//  QuizResultView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rainbowColor: Color = .red
    @State private var animationAngle: Double = 0
    let score: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .frame(
                        width: geometry.size.width * 2 / 3,
                        height: geometry.size.height / 2
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(rainbowColor, lineWidth: 5)
                    )
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            animationAngle = 360
                        }
                    }
                
                VStack {
                    Text("Your Score is \(score) points!")
                        .frame(
                            width: geometry.size.width / 2,
                            height: geometry.size.height / 4
                        )
                        .font(.title)
                        .multilineTextAlignment(.center)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.primary, lineWidth: 5)
                            .frame(
                                width: geometry.size.width / 2,
                                height: 60
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.primary.opacity(0.1))
                            )
                            .shadow(radius: 10)
                        
                        Text("Return to Title")
                            .font(.custom("ArialRoundedMTBold", size: 24))
                    }
                    .onTapGesture {
                        dismiss()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            startColorAnimation()
        }
    }
    
    private func startColorAnimation() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                rainbowColor = colors[currentIndex]
            }
            currentIndex = (currentIndex + 1) % colors.count
        }
    }
}

#Preview {
    QuizResultView(score: 1)
}
