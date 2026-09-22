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
    @State private var scoreCalculator = ScoreCalculator()
    @State private var answerRecords: [QuizAnswerRecord] = []
    @State private var quizData: [QuizEntity]
    @State private var remainingSeconds: Int
    @State private var timer: Timer?
    /// 現在の問題が表示された時刻。速度ボーナスの計測基準
    @State private var questionStartDate: Date = Date()

    let difficulty: Difficulty
    let gameMode: GameMode
    let manager = QuizDataManager()
    let range: QuizRange
    let questionCount: QuizQuestionCount

    init(
        difficulty: Difficulty,
        gameMode: GameMode = .practice,
        range: QuizRange? = nil,
        questionCount: QuizQuestionCount = .default
    ) {
        let resolvedRange = range ?? difficulty.defaultRange
        self.difficulty = difficulty
        self.gameMode = gameMode
        self.range = resolvedRange
        self.questionCount = questionCount
        _quizData = State(
            initialValue: manager.makeQuizData(
                difficulty: difficulty,
                range: resolvedRange,
                questionCount: questionCount
            )
        )
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
                        quizData: quizData,
                        currentCombo: scoreCalculator.currentCombo
                    )
                    .frame(height: geometry.size.height / 2)
                    
                    Spacer()
                    
                    QuizButtonView(
                        quizData: quizData,
                        difficulty: difficulty,
                        questionStartDate: questionStartDate,
                        scoreCalculator: $scoreCalculator,
                        quizIndex: $quizNumber,
                        isPresentedResult: $isPresentedResult,
                        answerRecords: $answerRecords
                    )
                    .frame(height: geometry.size.height / 3)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                if isPresentedResult {
                    QuizResultView(
                        score: scoreCalculator.totalScore,
                        correctCount: scoreCalculator.correctCount,
                        maxCombo: scoreCalculator.maxCombo,
                        answerRecords: answerRecords,
                        gameMode: gameMode
                    )
                }
            }
        }
        .sendAnalyticsScreen(.quiz)
        .onAppear {
            startTimerIfNeeded()
            // 1 問目が表示された時点を経過時間の基準にする
            questionStartDate = Date()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: quizNumber) { _, newValue in
            // 次の問題に切り替わった時点を経過時間の基準にする
            questionStartDate = Date()
            refillQuizDataIfNeeded(currentIndex: newValue)
        }
        .onChange(of: isPresentedResult) { _, isPresented in
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
        isPresentedResult = true
    }

    /// タイムアタックでは制限時間内に問題が尽きないよう、残りが少なくなったら追加生成する
    func refillQuizDataIfNeeded(currentIndex: Int) {
        guard gameMode == .timeAttack else { return }
        guard currentIndex >= quizData.count - Self.refillThreshold else { return }
        quizData.append(
            contentsOf: manager.makeQuizData(
                difficulty: difficulty,
                range: range,
                questionCount: questionCount
            )
        )
    }
}

#Preview {
    QuizView(difficulty: .easy, range: .oneOrTwoDigits, questionCount: .default)
}
