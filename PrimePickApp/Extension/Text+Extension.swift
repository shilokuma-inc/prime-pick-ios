//
//  Text+Extension.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/25.
//

import SwiftUI

public extension View {
    func gamingText() -> some View {
        self.modifier(GamingText())
    }
}

struct GamingText: ViewModifier {
    @State private var hue: Double = 0

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.white)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.red, Color.orange, Color.yellow, Color.green,
                        Color.blue, Color.purple, Color.red
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(content)
                .hueRotation(Angle(degrees: hue))
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    hue = 360
                }
            }
    }
}

#Preview {
    Text("Gaming ON!")
        .gamingText()
}
