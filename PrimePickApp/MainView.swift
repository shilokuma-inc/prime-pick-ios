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
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
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
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 10)
                    
                    NavigationLink(destination: LazyView(QuizView(difficulty: "Normal"))) {
                        Text("Normal")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
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
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 10)
                    
                    NavigationLink(destination: LazyView(QuizView(difficulty: "Easy"))) {
                        Text("Easy")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.green, Color.yellow]),
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
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 10)
                    
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
