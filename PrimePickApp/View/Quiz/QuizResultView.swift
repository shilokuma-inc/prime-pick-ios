//
//  QuizResultView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/31.
//

import SwiftUI

struct QuizResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rainbowColor: Color = .red
    let score: Int
    let answerRecords: [QuizAnswerRecord]
    var gameMode: GameMode = .practice

    /// 復習一覧に出すのは間違えた問題だけ
    private var missedRecords: [QuizAnswerRecord] {
        answerRecords.filter { !$0.isAnswerCorrect }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Your Score is \(score) points!")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)

                    if gameMode.isTimeAttack {
                        Text("Correct \(score) / Answered \(answerRecords.count)")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                    }

                    reviewSection

                    returnToTitleButton
                }
                .padding(20)
                .frame(width: geometry.size.width * 5 / 6)
                .frame(maxHeight: geometry.size.height * 5 / 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(rainbowColor, lineWidth: 5)
                )
                .shadow(radius: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .sendAnalyticsScreen(.quizResult)
        .onAppear {
            startColorAnimation()
        }
    }

    @ViewBuilder
    private var reviewSection: some View {
        if missedRecords.isEmpty {
            Text("Perfect! All questions correct!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Missed Questions")
                    .font(.headline)

                // 問題数が増えても収まるようにスクロールさせる
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(missedRecords) { record in
                            reviewRow(record)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func reviewRow(_ record: QuizAnswerRecord) -> some View {
        HStack(spacing: 8) {
            Text(verbatim: "❌")

            factorizationText(for: record.number)
                .font(.body)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer(minLength: 0)
        }
    }

    /// 素因数分解の表示。合成数は `391 = 17 × 23`、素数などは文言で返す。
    private func factorizationText(for number: Int) -> Text {
        let factors = PrimeFactorization.factors(of: number)
        if factors.count >= 2 {
            let expression = factors.map(String.init).joined(separator: " × ")
            return Text(verbatim: "\(number) = \(expression)")
        } else if factors.count == 1 {
            return Text("\(number) is a prime number")
        } else {
            // 1 以下は素因数を持たないため、専用の文言にする
            return Text("\(number) is not a prime number")
        }
    }

    private var returnToTitleButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.primary, lineWidth: 5)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.primary.opacity(0.1))
                )
                .shadow(radius: 10)

            Text("Return to Title")
                .font(.custom("ArialRoundedMTBold", size: 24))
        }
        .frame(height: 60)
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
    }

    private func startColorAnimation() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        var currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                rainbowColor = colors[currentIndex]
            }
            currentIndex = (currentIndex + 1) % colors.count
        }
    }
}

#Preview {
    QuizResultView(
        score: 7,
        answerRecords: [
            QuizAnswerRecord(id: 1, number: 391, isPrime: false, answeredPrime: true),
            QuizAnswerRecord(id: 2, number: 397, isPrime: true, answeredPrime: false),
            QuizAnswerRecord(id: 3, number: 8, isPrime: false, answeredPrime: true),
            QuizAnswerRecord(id: 4, number: 1, isPrime: false, answeredPrime: true)
        ]
    )
}
