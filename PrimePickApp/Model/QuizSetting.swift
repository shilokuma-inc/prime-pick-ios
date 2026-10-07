//
//  QuizSetting.swift
//  PrimePickApp
//

import Foundation

/// タイトル画面で選んだクイズの設定。難易度ボタンから `QuizView` へ渡す
///
/// 出題範囲は難易度から決まる（`Difficulty.range`）ので持たない。
///
/// `NavigationStack` の value として使うため `Hashable` にしている。
struct QuizSetting: Hashable {
    let difficulty: Difficulty
    let gameMode: GameMode
    let questionCount: QuizQuestionCount
    /// どの画面から始めたか。計測（`quiz_start` の `source`）だけに使う
    var source: QuizStartSource = .title
}
