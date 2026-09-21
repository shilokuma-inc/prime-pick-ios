//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @State private var hue: Double = 0
    @State private var isHowToPlayPresented: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Prime Pick")
                        .gamingText()
                        .font(.custom("Helvetica Neue", size: 60))
                        .fontWeight(.bold)
                    
                    
                    Spacer()
                    
                    SelectDifficultyButtonView()
                    
                    howToPlayButton
                    
                    Spacer()
                }
            }
            .sheet(isPresented: $isHowToPlayPresented) {
                HowToPlayView()
            }
            .sendAnalyticsScreen(.main)
        }
    }
}

private extension MainView {
    var howToPlayButton: some View {
        Button {
            isHowToPlayPresented = true
        } label: {
            Label("How to Play", systemImage: "questionmark.circle")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.4), lineWidth: 2)
                )
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

#Preview {
    MainView()
}
