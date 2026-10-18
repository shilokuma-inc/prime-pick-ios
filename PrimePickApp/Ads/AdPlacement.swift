//
//  AdPlacement.swift
//  PrimePickApp
//

/// バナー広告の置き場所。ホーム（`MainView`）と出題中（`QuizView`）には置かない
enum AdPlacement: CaseIterable {
    /// 練習・タイムアタックの結果（`QuizResultView`）の下部
    case quizResult
    /// デイリーチャレンジの結果（`DailyChallengeResultView`）の下部
    case dailyChallengeResult

    /// 広告を出す置き場所。出す場所を変えるときはここだけを直す
    static let enabled: Set<AdPlacement> = [.quizResult, .dailyChallengeResult]
}
