//
//  QuizSetting.swift
//  PrimePickApp
//

import Foundation

/// タイトル画面で選んだクイズの設定。難易度ボタンから `QuizView` へ渡す
///
/// `NavigationStack` の value として使うため `Hashable` にしている。
struct QuizSetting: Hashable {
    let difficulty: Difficulty
    let gameMode: GameMode
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジ（`Difficulty.defaultRange`）を使う
    let range: QuizRange?
    let questionCount: QuizQuestionCount
    /// どの画面から始めたか。計測（`quiz_start` の `source`）だけに使う
    var source: QuizStartSource = .title
}
