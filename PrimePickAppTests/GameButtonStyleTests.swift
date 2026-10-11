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
}
