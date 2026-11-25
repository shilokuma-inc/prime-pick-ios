//
//  QuizPlayFinishStateTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class QuizPlayFinishStateTests: XCTestCase {

    func testNotFinishedBeforeFinish() {
        let state = QuizPlayFinishState()

        XCTAssertFalse(state.hasFinishedPlay)
        XCTAssertFalse(state.isNewRecord)
    }

    /// 終わりの処理は 1 プレイで 1 回だけ行い、自己ベストを更新したかを残す
    func testFinishOnceRunsFinishOnlyOnce() {
        let state = QuizPlayFinishState()
        var finishCount = 0

        state.finishOnce {
            finishCount += 1
            return true
        }
        state.finishOnce {
            finishCount += 1
            return false
        }

        XCTAssertEqual(finishCount, 1)
        XCTAssertTrue(state.hasFinishedPlay)
        XCTAssertTrue(state.isNewRecord, "2 回目の結果で上書きしない")
    }

    /// 出来事のクロージャが持つ参照から書いた結果は、画面が持つ参照からも読める（#554。値型の `@State` では届かなかった）
    func testResultWrittenThroughAnotherReferenceIsVisible() {
        let state = QuizPlayFinishState()
        let capturedByEventHandler = state

        capturedByEventHandler.finishOnce { true }

        XCTAssertTrue(state.hasFinishedPlay)
        XCTAssertTrue(state.isNewRecord)
    }
}
