//
//  ReplayableQuizView.swift
//  PrimePickApp
//

import SwiftUI

/// タイトル画面から始める練習・タイムアタックの出題画面。結果画面の「もう一度」で同じ設定のプレイを作り直す（#547）
///
/// `NavigationPath` は変えず、`QuizView` の識別子だけを替えて新しいプレイにする。前のプレイの画面は残らないので、戻るとタイトルに戻る。
/// タイムアタックでも確認のカード（Discussion #394）は挟まない。直前に同じ設定で遊んだばかりなので、すぐ始める。
struct ReplayableQuizView: View {
    let setting: QuizSetting

    /// いまのプレイの識別子。「もう一度」で替える
    @State private var playID = UUID()
    /// 「もう一度」で始めたか。`quiz_start` の `source` をタイトル・デイリーの結果画面からの開始と分ける
    @State private var isReplay = false

    var body: some View {
        QuizView(
            difficulty: setting.difficulty,
            gameMode: setting.gameMode,
            questionCount: setting.questionCount,
            source: Self.source(for: setting, isReplay: isReplay),
            onPlayAgain: playAgain
        )
        .id(playID)
    }

    /// `quiz_start` の `source`。最初のプレイは設定のまま（タイトル・デイリーの結果画面）、作り直したプレイは「もう一度」
    static func source(for setting: QuizSetting, isReplay: Bool) -> QuizStartSource {
        isReplay ? .playAgain : setting.source
    }

    private func playAgain() {
        isReplay = true
        playID = UUID()
    }
}
