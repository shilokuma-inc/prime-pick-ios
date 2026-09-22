//
//  QuizView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/05/15.
//

import SwiftUI

struct QuizView: View {
    /// タイムアタックで残りの問題がこの数以下になったら追加生成する
    private static let refillThreshold: Int = 3

    @Environment(\.dismiss) private var dismiss
    @State private var quizNumber: Int = 0
    @State var isPresentedResult: Bool = false
    @State var resultScore: Int = 0
    @State private var quizData: [QuizEntity]
    @State private var remainingSeconds: Int
    @State private var answeredQuizNumber: Int = 0
    @State private var timer: Timer?
    
    let primeData = PrimeData()
    let difficulty: Difficulty
    let gameMode: GameMode
    let manager = QuizDataManager()
    
    init(difficulty: Difficulty, gameMode: GameMode = .practice) {
        self.difficulty = difficulty
        self.gameMode = gameMode
        _quizData = State(initialValue: manager.makeQuizData(difficulty: difficulty))
        _remainingSeconds = State(initialValue: gameMode.timeLimitSeconds ?? 0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: .zero) {
                    QuizContentView(
                        quizNumber: $quizNumber,
                        difficulty: difficulty,
                        gameMode: gameMode,
                        remainingSeconds: remainingSeconds,
                        quizData: quizData
                    )
                    .frame(height: geometry.size.height / 2)
                    
                    Spacer()
                    
                    QuizButtonView(
                        quizData: quizData,
                        correctQuizNumber: $resultScore,
                        quizIndex: $quizNumber,
                        isPresentedResult: $isPresentedResult
                    )
                    .frame(height: geometry.size.height / 3)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                if isPresentedResult {
                    QuizResultView(
                        score: resultScore,
                        gameMode: gameMode,
                        answeredQuizNumber: answeredQuizNumber
                    )
                }
            }
        }
        .sendAnalyticsScreen(.quiz)
        .onAppear {
            startTimerIfNeeded()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: quizNumber) { newValue in
            refillQuizDataIfNeeded(currentIndex: newValue)
        }
        .onChange(of: isPresentedResult) { isPresented in
            // 10 問を解き終えた場合など、タイムアップ以外の終了でもタイマーを止める
            if isPresented {
                stopTimer()
            }
        }
    }
}

private extension QuizView {
    /// タイムアタック時のみ 1 秒ごとのカウントダウンを開始する
    func startTimerIfNeeded() {
        guard gameMode == .timeAttack, timer == nil, !isPresentedResult else { return }
        let scheduledTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countDown()
        }
        // スクロールなどのトラッキング中でもカウントダウンを止めない
        RunLoop.main.add(scheduledTimer, forMode: .common)
        timer = scheduledTimer
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func countDown() {
        guard !isPresentedResult else { return }
        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            finishByTimeUp()
        }
    }

    /// 時間切れでリザルトを表示する
    func finishByTimeUp() {
        stopTimer()
        answeredQuizNumber = quizNumber
        isPresentedResult = true
    }

    /// タイムアタックでは制限時間内に問題が尽きないよう、残りが少なくなったら追加生成する
    func refillQuizDataIfNeeded(currentIndex: Int) {
        guard gameMode == .timeAttack else { return }
        guard currentIndex >= quizData.count - Self.refillThreshold else { return }
        quizData.append(contentsOf: manager.makeQuizData(difficulty: difficulty))
    }
}

#Preview {
    QuizView(difficulty: .easy)
}
