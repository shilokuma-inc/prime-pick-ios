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
                Color("appBackground")
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

#Preview {
    MainView()
}
