//
//  QuizResultView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizResultView: View {
    @Environment(\.dismiss) private var dismiss
    let score: Int
    
    var body: some View {
        Text("You Score is \(score) points!")
    }
}

#Preview {
    QuizResultView(score: 1)
}
