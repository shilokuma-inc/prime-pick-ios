//
//  GameButtonStyleTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class GameButtonStyleTests: XCTestCase {

    // MARK: - 沈み込み

    /// 押すと上面が側面の厚みの分だけ沈み、離すと元に戻る
    func testFaceSinksByDepthWhilePressed() {
        let appearance = GameButtonAppearance(color: .blue, depth: 6)
        XCTAssertEqual(appearance.faceOffset(isPressed: false), 0)
        XCTAssertEqual(appearance.faceOffset(isPressed: true), 6)
    }

    func testDefaultDepthIsUsedWhenNotSpecified() {
        let appearance = GameButtonAppearance(colors: [.red, .orange])
        XCTAssertEqual(appearance.depth, GameButtonAppearance.defaultDepth)
        XCTAssertEqual(appearance.faceOffset(isPressed: true), GameButtonAppearance.defaultDepth)
    }

    func testReduceMotionDisablesPressAnimation() {
        XCTAssertNil(GameButtonAppearance.pressAnimation(reduceMotion: true))
        XCTAssertNotNil(GameButtonAppearance.pressAnimation(reduceMotion: false))
    }

    /// 色の付いていないボタンは側面色を明示する（上面を暗くすると背景と見分けにくいため）。厚みは指定どおり
    func testNeutralAppearanceHasExplicitSideColor() {
        let appearance = GameButtonAppearance.neutral(shape: .capsule, depth: 4)
        XCTAssertNotNil(appearance.side)
        XCTAssertEqual(appearance.faceOffset(isPressed: true), 4)
    }

    /// 側面色を渡すと、側面だけその色になる（解答ボタン）
    func testNeutralAppearanceUsesGivenSideColor() {
        let appearance = GameButtonAppearance.neutral(side: .green)
        XCTAssertEqual(appearance.side, .green)
        XCTAssertEqual(appearance.depth, GameButtonAppearance.defaultDepth)
    }

    // MARK: - 触覚・効果音

    /// 押し始めた瞬間だけ返し、離したときや押し続けている間は返さない
    func testPressFeedbackPlaysOnlyOnPressDown() {
        XCTAssertTrue(GameButtonStyle.shouldPlayPressFeedback(wasPressed: false, isPressed: true, isScreenshotDemo: false))
        XCTAssertFalse(GameButtonStyle.shouldPlayPressFeedback(wasPressed: true, isPressed: false, isScreenshotDemo: false))
        XCTAssertFalse(GameButtonStyle.shouldPlayPressFeedback(wasPressed: true, isPressed: true, isScreenshotDemo: false))
        XCTAssertFalse(GameButtonStyle.shouldPlayPressFeedback(wasPressed: false, isPressed: false, isScreenshotDemo: false))
    }

    /// 撮影モードでは触覚・効果音を返さない
    func testPressFeedbackIsSilentInScreenshotDemo() {
        XCTAssertFalse(GameButtonStyle.shouldPlayPressFeedback(wasPressed: false, isPressed: true, isScreenshotDemo: true))
    }

    // MARK: - ボタンごとの押下音

    /// GameButtonStyle を使うボタンは、それぞれの View の静的なプロパティで押下音を指定する。
    /// 役割で分ける前の今の音のまま（確認カードの「Start」だけ進む押下音、ほかは戻る押下音）
    func testEveryGameButtonKeepsItsCurrentPressSound() {
        let expected: [(button: String, sound: SoundEffect, current: SoundEffect)] = [
            ("難易度ボタン", SelectDifficultyButtonView.pressSound, .buttonPressBack),
            ("今日のチャレンジのカード", MainView.dailyChallengeCardPressSound, .buttonPressBack),
            ("遊び方", MainView.howToPlayPressSound, .buttonPressBack),
            ("確認カードの Start", TimeAttackStartConfirmationView.startPressSound, .buttonPressForward),
            ("確認カードの Quit", TimeAttackStartConfirmationView.quitPressSound, .buttonPressBack),
            ("結果画面のタイトルに戻る", QuizResultView.returnToTitlePressSound, .buttonPressBack),
            ("デイリーの結果のタイムアタックで遊ぶ", DailyChallengeResultView.playTimeAttackPressSound, .buttonPressBack),
            ("デイリーの結果のタイトルに戻る", DailyChallengeResultView.returnToTitlePressSound, .buttonPressBack)
        ]
        for (button, sound, current) in expected {
            XCTAssertEqual(sound, current, button)
        }
    }

    // MARK: - 確認カードの押下音

    /// 確認カードの「Start」は進む押下音、「Quit」は戻る押下音で、聞き分けられるよう別の音源にする（Discussion #454）
    func testStartConfirmationButtonsUseForwardAndBackSounds() {
        XCTAssertEqual(TimeAttackStartConfirmationView.startPressSound, .buttonPressForward)
        XCTAssertEqual(TimeAttackStartConfirmationView.quitPressSound, .buttonPressBack)
        XCTAssertNotEqual(
            TimeAttackStartConfirmationView.startPressSound.resourceName,
            TimeAttackStartConfirmationView.quitPressSound.resourceName
        )
    }

    // MARK: - 難易度ボタンの側面色

    /// ダークモードのエキスパートだけ側面色を明示し、ほかは上面のグラデーションを暗くして使う
    func testOnlyExpertInDarkModeHasExplicitSideColor() {
        for difficulty in Difficulty.allCases {
            XCTAssertNil(difficulty.gameButtonSideColor(for: .light), "\(difficulty)")
            if difficulty == .expert {
                XCTAssertNotNil(difficulty.gameButtonSideColor(for: .dark))
            } else {
                XCTAssertNil(difficulty.gameButtonSideColor(for: .dark), "\(difficulty)")
            }
        }
    }
}
