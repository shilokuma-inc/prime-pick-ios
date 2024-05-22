//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("appBlue")
                    .ignoresSafeArea()
                
                VStack {
                    Text("PrimePick")
                        .font(.custom("Helvetica Neue", size: 40))
                        .fontWeight(.bold)
                        .padding(.top, 100)
                        .padding(.bottom, 30)
                    
                    Spacer()
                    
                    Text("Select Difficulty")
                        .font(.headline)
                        .padding()
                    
                    NavigationLink(destination: LazyView(QuizView(difficulty: "Hard"))) {
                        Text("Hard")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 10)
                    
                    NavigationLink(destination: LazyView(QuizView(difficulty: "Normal"))) {
                        Text("Normal")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 10)
                    
                    NavigationLink(destination: LazyView(QuizView(difficulty: "Easy"))) {
                        Text("Easy")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 50)
                    
                    Spacer()
                }
            }
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
