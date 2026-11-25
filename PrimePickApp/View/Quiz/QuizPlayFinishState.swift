//
//  QuizPlayFinishState.swift
//  PrimePickApp
//

import Foundation
import Observation

/// 1 プレイの終わりの処理を済ませたかと、その結果（自己ベストを更新したか・タイムアタックのそれまでの記録との比べ）
///
/// `QuizView` はプレイの終わりの処理を `QuizSession.onEvent`（時間切れは Timer から届く）の中で行う。
/// そこで値型の `@State` に書いた `isNewRecord` が結果画面に届かず、タイムアタックで自己ベストを更新しても
/// NEW RECORD! が出なかった（iOS 26 の Simulator で確認。記録の保存はできていた。#554）。
/// `QuizSession` と同じく参照型にして `@State` で持ち、画面はこのオブジェクトの値を読む。
@Observable
final class QuizPlayFinishState {
    /// プレイの終わりの処理を済ませたか。1 プレイで 2 回記録しないために使う
    private(set) var hasFinishedPlay = false
    /// プレイの終わりの処理の結果。リザルトで NEW RECORD! と、タイムアタックのそれまでの記録との比べ（#549）を出すために使う
    private(set) var result = QuizPlayFinishResult()

    /// このプレイで自己ベストを更新したか
    var isNewRecord: Bool {
        result.isNewRecord
    }

    /// プレイの終わりの処理（`finish`）を 1 回だけ行い、その結果を残す
    func finishOnce(_ finish: () -> QuizPlayFinishResult) {
        guard !hasFinishedPlay else { return }
        hasFinishedPlay = true
        result = finish()
    }
}
