//
//  DailyChallengeView.swift
//  PrimePickApp
//

import SwiftUI

/// デイリーチャレンジの画面。今日まだ始めていなければ 10 問を出し、始めていれば結果だけを出す
///
/// 1 日 1 回だけ遊べる（Discussion #181 本文 2-2）。開いた瞬間に始めた記録を保存して、その日の挑戦権を使う。
/// 解き終えたら結果画面（`DailyChallengeResultView`）に切り替える。
struct DailyChallengeView: View {
    /// 1 日の問題数。v1 の生成器が作る問題数と同じ
    static let questionCount: QuizQuestionCount = .ten

    var store: any DailyChallengeStore = UserDefaultsDailyChallengeStore()
    var generator: DailyChallengeGenerator = .v1
    /// 結果画面の「タイムアタックで遊ぶ」を押したとき。nil ならボタンを出さない
    var onPlayTimeAttack: (() -> Void)?

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
                    finisher: DailyChallengePlayFinisher(
                        startedRecord: startedRecord,
                        store: store,
                        onFinish: { record in phase = .alreadyPlayed(record) }
                    )
                )
            case .alreadyPlayed(let record):
                DailyChallengeResultView(
                    result: DailyChallengeResult(record: record, records: store.allRecords(), today: DailyChallengeDay.today()),
                    onPlayTimeAttack: onPlayTimeAttack
                )
            }
        }
        .onAppear(perform: startIfNeeded)
    }

    /// 最初に表示されたときだけ、今日の記録の有無で遊ぶか要約を出すかを決める
    private func startIfNeeded() {
        guard case .loading = phase else { return }
        let today = DailyChallengeDay.today()
        // 始める前のストリーク。始めた記録（未完了）を保存する前に数える
        let streakBefore = DailyChallengeStreak(records: store.allRecords(), today: today).current
        phase = Self.phase(for: today, now: Date(), store: store, generator: generator)
        if case .playing = phase {
            FirebaseAnalytics().sendDailyChallenge(.start(dayNumber: today.dayNumber, streakBefore: streakBefore))
        }
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
