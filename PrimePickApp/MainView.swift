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
                
                NavigationLink(destination: QuizView(difficulty: "Hard")) {
                    Text("Hard")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 10)
                
                NavigationLink(destination: QuizView(difficulty: "Normal")) {
                    Text("Normal")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 10)
                
                NavigationLink(destination: QuizView(difficulty: "Easy")) {
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

#Preview {
    MainView()
}
