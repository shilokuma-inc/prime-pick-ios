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
