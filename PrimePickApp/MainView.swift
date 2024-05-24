//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @State private var hue: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("appBlue")
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Prime Pick")
                        .font(.custom("Helvetica Neue", size: 60))
                        .foregroundStyle(.black)
                        .fontWeight(.bold)
                        .offset(x: 2, y: 2)
                        .foregroundColor(Color.white) // 文字自体を白に設定
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red, Color.orange, Color.yellow, Color.green,
                                    Color.blue, Color.purple, Color.red
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("Prime Pick")
                                    .font(.custom("Helvetica Neue", size: 60))
                                    .fontWeight(.bold)
                            )
                            .hueRotation(Angle(degrees: hue))
                        )
                        .onAppear {
                            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                hue = 360
                            }
                        }
                    
                    Spacer()
                    
                    selectDifficultyButton(difficulty: .hard)
                    
                    selectDifficultyButton(difficulty: .normal)
                    
                    selectDifficultyButton(difficulty: .easy)
                    
                    Spacer()
                }
            }
        }
    }
}

extension MainView {
    func selectDifficultyButton(difficulty: Difficulty) -> some View {
        NavigationLink(destination: LazyView(QuizView(difficulty: difficulty))) {
            Text(difficulty.rawValue)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: difficulty.gradientColors),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 5, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                )
                .padding(.horizontal, 50)
                .padding(.bottom, 10)
        }
    }
}

extension Difficulty {
    public var gradientColors: [Color] {
        switch self {
        case .easy:
            return [Color.green, Color.yellow]
        case .normal:
            return [Color.purple, Color.blue]
        case .hard:
            return [Color.red, Color.purple]
        }
    }
}
                                   
struct LazyView<Content: View>: View {
   let content: () -> Content
   
   init(_ content: @autoclosure @escaping () -> Content) {
       self.content = content
   }
   
   var body: Content {
       content()
   }
}

struct RainbowTextModifier: AnimatableModifier {
    var hue: Double

    var animatableData: Double {
        get { hue }
        set { hue = newValue }
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(hue: hue, saturation: 1, brightness: 1))
            .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
    }
}

#Preview {
    MainView()
}
