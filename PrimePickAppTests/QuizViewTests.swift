//
//  QuizViewTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizViewTests: XCTestCase {

    // MARK: - 解答の受け付け

    /// 指が触れた瞬間に解答しても、リザルト表示後・次の問題を待っている間・誤答後のロック中は受け付けない
    func testAcceptsAnswerOnlyWhenNotBlocked() {
        XCTAssertTrue(QuizButtonView.acceptsAnswer(isPresentedResult: false, isWaitingToAdvance: false, isInputLocked: false))
        XCTAssertFalse(QuizButtonView.acceptsAnswer(isPresentedResult: true, isWaitingToAdvance: false, isInputLocked: false))
        XCTAssertFalse(QuizButtonView.acceptsAnswer(isPresentedResult: false, isWaitingToAdvance: true, isInputLocked: false))
        XCTAssertFalse(QuizButtonView.acceptsAnswer(isPresentedResult: false, isWaitingToAdvance: false, isInputLocked: true))
    }

    // MARK: - 最初の出題

    /// デイリーチャレンジのように外で作った出題を渡したときは、それをそのまま使い、自前では作らない
    func testInitialQuizDataUsesProvidedQuizData() {
        let provided = makeQuizData(seed: 1)
        var madeCount = 0
        let quizData = QuizView.initialQuizData(provided: provided) {
            madeCount += 1
            return makeQuizData(seed: 2)
        }
        XCTAssertEqual(quizData.map(\.number), provided.map(\.number))
        XCTAssertEqual(madeCount, 0)
    }

    /// 出題を渡さないタイトル画面からの遷移は、従来どおり自前で作る
    func testInitialQuizDataMakesQuizDataWhenNotProvided() {
        let made = makeQuizData(seed: 2)
        let quizData = QuizView.initialQuizData(provided: nil) { made }
        XCTAssertEqual(quizData.map(\.number), made.map(\.number))
    }

    /// 空の出題は 1 問目の表示で範囲外アクセスになるため、渡されなかったものとして扱う
    func testInitialQuizDataMakesQuizDataWhenProvidedIsEmpty() {
        let made = makeQuizData(seed: 3)
        let quizData = QuizView.initialQuizData(provided: []) { made }
        XCTAssertEqual(quizData.map(\.number), made.map(\.number))
    }

    private func makeQuizData(seed: UInt64) -> [QuizEntity] {
        var generator = SeededGenerator(seed: seed)
        return QuizDataManager(primeProbability: 0.5).makeQuizData(
            difficulty: .normal,
            range: .threeDigits,
            questionCount: .ten,
            using: &generator
        )
    }
}
