//
//  DailyChallengeView.swift
//  PrimePickApp
//

import SwiftUI

/// デイリーチャレンジの画面。今日まだ始めていなければ 10 問を出し、始めていれば記録の要約だけを出す
///
/// 1 日 1 回だけ遊べる（Discussion #181 本文 2-2）。開いた瞬間に始めた記録を保存して、その日の挑戦権を使う。
struct DailyChallengeView: View {
    /// 1 日の問題数。v1 の生成器が作る問題数と同じ
    static let questionCount: QuizQuestionCount = .ten

    var store: any DailyChallengeStore = UserDefaultsDailyChallengeStore()
    var generator: DailyChallengeGenerator = .v1

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                Color.appBackground
                    .ignoresSafeArea()
            case .playing(let quizData, let startedRecord):
                QuizView(
                    difficulty: quizData.first?.difficulty ?? .easy,
                    gameMode: .dailyChallenge,
                    questionCount: Self.questionCount,
                    quizData: quizData,
                    finisher: DailyChallengePlayFinisher(startedRecord: startedRecord, store: store)
                )
            case .alreadyPlayed(let record):
                DailyChallengePlayedView(record: record)
            }
        }
        .onAppear(perform: startIfNeeded)
    }

    /// 最初に表示されたときだけ、今日の記録の有無で遊ぶか要約を出すかを決める
    private func startIfNeeded() {
        guard case .loading = phase else { return }
        phase = Self.phase(for: DailyChallengeDay.today(), now: Date(), store: store, generator: generator)
    }

    /// 今日の記録があれば要約、無ければ始めた記録を保存して出題する
    static func phase(
        for today: DailyChallengeDay,
        now: Date,
        store: any DailyChallengeStore,
        generator: DailyChallengeGenerator
    ) -> Phase {
        if let record = store.record(dayKey: today.dayKey) {
            return .alreadyPlayed(record)
        }
        let quizData = generator.makeQuizData(dayKey: today.dayKey)
        let startedRecord = DailyChallengeRecord.started(
            dayKey: today.dayKey,
            generatorVersion: generator.version,
            questionCount: quizData.count,
            startedAt: now
        )
        store.save(startedRecord)
        return .playing(quizData: quizData, startedRecord: startedRecord)
    }

    enum Phase {
        case loading
        case playing(quizData: [QuizEntity], startedRecord: DailyChallengeRecord)
        case alreadyPlayed(DailyChallengeRecord)
    }
}

/// 挑戦済みの日に出す要約。結果画面（後続タスク）ができるまでの最小限の表示
private struct DailyChallengePlayedView: View {
    let record: DailyChallengeRecord

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Today's challenge is done")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                if record.isCompleted {
                    Text("\(record.correctCount) / \(record.results.count) correct")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                } else {
                    Text("Incomplete \(record.answeredCount) / \(record.results.count)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                }

                Text("Come back tomorrow for a new challenge.")
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }
}
