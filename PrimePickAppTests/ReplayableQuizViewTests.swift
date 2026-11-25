//
//  ReplayableQuizViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

/// 結果画面の「もう一度」で始めたプレイの計測（#547）
final class ReplayableQuizViewTests: XCTestCase {

    /// 最初のプレイは、始めた画面（タイトル・デイリーの結果画面）の `source` のまま送る
    func testFirstPlayKeepsSourceOfSetting() {
        let fromTitle = QuizSetting(difficulty: .easy, gameMode: .practice, questionCount: .ten)
        let fromDailyResult = DailyChallengeResult.timeAttackSetting(selectedGameMode: .practice, selectedQuestionCount: .ten)

        XCTAssertEqual(ReplayableQuizView.source(for: fromTitle, isReplay: false), .title)
        XCTAssertEqual(ReplayableQuizView.source(for: fromDailyResult, isReplay: false), .dailyResult)
    }

    /// 「もう一度」で作り直したプレイは、どこから始めた設定でも `play_again` で数える
    func testReplayIsCountedAsPlayAgain() {
        let fromTitle = QuizSetting(difficulty: .hard, gameMode: .timeAttack(.thirtySeconds), questionCount: .ten)
        let fromDailyResult = DailyChallengeResult.timeAttackSetting(selectedGameMode: .practice, selectedQuestionCount: .ten)

        XCTAssertEqual(ReplayableQuizView.source(for: fromTitle, isReplay: true), .playAgain)
        XCTAssertEqual(ReplayableQuizView.source(for: fromDailyResult, isReplay: true), .playAgain)
    }

    /// Firebase に送る値。変えると、それまでの「もう一度」の数と続けて比べられなくなる
    func testPlayAgainSourceValue() {
        let event = QuizView.quizStartEvent(
            gameMode: .timeAttack(.fifteenSeconds),
            difficulty: .normal,
            range: .threeDigits,
            questionCount: .ten,
            source: .playAgain
        )
        XCTAssertEqual(event?.parameters["source"] as? String, "play_again")
    }
}
