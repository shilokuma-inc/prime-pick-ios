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
                        .gamingText()
                        .font(.custom("Helvetica Neue", size: 60))
                        .fontWeight(.bold)
                    
                    
                    Spacer()
                    
                    SelectDifficultyButtonView()
                    
                    Spacer()
                }
            }
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
