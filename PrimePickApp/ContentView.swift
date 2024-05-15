//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
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
            
            Button(action: {
                // Hardボタンのアクション
            }) {
                Text("Hard")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 10)
            
            Button(action: {
                // Normalボタンのアクション
            }) {
                Text("Normal")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 10)
            
            Button(action: {
                // Easyボタンのアクション
            }) {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
