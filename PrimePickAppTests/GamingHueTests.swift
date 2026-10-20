//
//  GamingHueTests.swift
//  PrimePickAppTests
//

import XCTest
@testable import PrimePickApp

final class GamingHueTests: XCTestCase {

    // MARK: - 回すかどうか

    func testAnimatesNormally() {
        XCTAssertTrue(GamingHue.isAnimating(reduceMotion: false, isScreenshotDemo: false))
    }

    func testStopsWhenReduceMotionIsOn() {
        XCTAssertFalse(GamingHue.isAnimating(reduceMotion: true, isScreenshotDemo: false))
    }

    func testStopsInScreenshotDemo() {
        XCTAssertFalse(GamingHue.isAnimating(reduceMotion: false, isScreenshotDemo: true))
        XCTAssertFalse(GamingHue.isAnimating(reduceMotion: true, isScreenshotDemo: true))
    }

    // MARK: - 色相の回転

    func testDefaultCycleIsOneSecond() {
        XCTAssertEqual(GamingHue.defaultCycleDuration, 1)
    }

    func testDegreesFollowTimeWithinOneCycle() {
        let cases: [(seconds: TimeInterval, degrees: Double)] = [
            (0, 0), (0.25, 90), (0.5, 180), (0.75, 270), (1, 0), (2.5, 180)
        ]
        for (seconds, degrees) in cases {
            let date = Date(timeIntervalSinceReferenceDate: seconds)
            XCTAssertEqual(
                GamingHue.degrees(at: date, cycleDuration: 1, isAnimating: true), degrees,
                accuracy: 1e-9, "seconds=\(seconds)"
            )
        }
    }

    func testLongerCycleTurnsSlower() {
        let date = Date(timeIntervalSinceReferenceDate: 1)
        XCTAssertEqual(GamingHue.degrees(at: date, cycleDuration: 4, isAnimating: true), 90, accuracy: 1e-9)
    }

    func testDegreesStayInRange() {
        for seconds in stride(from: 0.0, to: 10.0, by: 0.37) {
            let degrees = GamingHue.degrees(
                at: Date(timeIntervalSinceReferenceDate: 812_345_678 + seconds), cycleDuration: 1, isAnimating: true
            )
            XCTAssertGreaterThanOrEqual(degrees, 0)
            XCTAssertLessThan(degrees, 360)
        }
    }

    func testDegreesAreZeroWhenStopped() {
        let date = Date(timeIntervalSinceReferenceDate: 0.25)
        XCTAssertEqual(GamingHue.degrees(at: date, cycleDuration: 1, isAnimating: false), 0)
    }

    func testDegreesAreZeroForNonPositiveCycle() {
        let date = Date(timeIntervalSinceReferenceDate: 0.25)
        XCTAssertEqual(GamingHue.degrees(at: date, cycleDuration: 0, isAnimating: true), 0)
        XCTAssertEqual(GamingHue.degrees(at: date, cycleDuration: -1, isAnimating: true), 0)
    }

    // MARK: - 速さを変えたときの位相のつながり

    func testPhaseFollowsAnchor() {
        let anchor = GamingHue.Anchor(date: Date(timeIntervalSinceReferenceDate: 100), phase: 0.25)
        let date = Date(timeIntervalSinceReferenceDate: 100.5)
        XCTAssertEqual(GamingHue.phase(at: date, anchor: anchor, cycleDuration: 2), 0.5, accuracy: 1e-9)
        XCTAssertEqual(GamingHue.phase(at: date, anchor: anchor, cycleDuration: 0.5), 0.25, accuracy: 1e-9)
    }

    /// 速さを変えた瞬間の色相は、変える前と同じ（色が飛ばない）
    func testResolvedAnchorKeepsHueContinuous() {
        let switchDate = Date(timeIntervalSinceReferenceDate: 812_345_678.3)
        let before = GamingHue.degrees(at: switchDate, cycleDuration: 1, isAnimating: true)
        for cycle in [0.4, 0.5, 0.65, 0.8] {
            let anchor = GamingHue.resolved(.zero, cycleDuration: cycle, at: switchDate)
            XCTAssertEqual(anchor.date, switchDate, "cycle=\(cycle)")
            XCTAssertEqual(anchor.cycleDuration, cycle, "cycle=\(cycle)")
            XCTAssertEqual(
                GamingHue.degrees(at: switchDate, anchor: anchor, cycleDuration: cycle, isAnimating: true), before,
                accuracy: 1e-6, "cycle=\(cycle)"
            )
        }
        // 変えた後は新しい速さで回る
        let anchor = GamingHue.resolved(.zero, cycleDuration: 0.4, at: switchDate)
        let later = switchDate.addingTimeInterval(0.1)
        let expected = (before + 360 * 0.1 / 0.4).truncatingRemainder(dividingBy: 360)
        // 8 億秒台の時刻に 0.1 秒を足すと丸めで 1e-7 秒ほどずれるので、1e-3 度まで許す
        XCTAssertEqual(GamingHue.degrees(at: later, anchor: anchor, cycleDuration: 0.4, isAnimating: true), expected, accuracy: 1e-3)
    }

    /// 速さが同じなら起点は変えない（描くたびに求め直しても、脈動・揺れの経過時間が 0 に戻らない）
    func testResolvedAnchorIsUnchangedForSameCycle() {
        let anchor = GamingHue.Anchor(date: Date(timeIntervalSinceReferenceDate: 100), phase: 0.3, cycleDuration: 0.5)
        XCTAssertEqual(GamingHue.resolved(anchor, cycleDuration: 0.5, at: Date(timeIntervalSinceReferenceDate: 200)), anchor)
    }

    // MARK: - 確認のカードの表示中の虹の激しさ（Discussion #394 Q3）

    private let difficultiesByLevel: [Difficulty] = [.easy, .normal, .hard, .expert]

    func testStandardStyleIsCurrentRainbow() {
        let style = GamingTextStyle.standard
        XCTAssertEqual(style.cycleDuration, 1)
        XCTAssertEqual(style.saturation, 1)
        XCTAssertNil(style.pulse)
        XCTAssertNil(style.shake)
        XCTAssertEqual(style.scale(elapsed: 0.3), 1)
        XCTAssertEqual(style.offset(elapsed: 0.3), 0)
    }

    /// 難しいほど速く回し、鮮やかにする。どれも今の 1 秒 1 周より速い
    func testHarderDifficultyTurnsFasterAndMoreVivid() {
        let styles = difficultiesByLevel.map { $0.confirmationTitleStyle(reduceMotion: false) }
        XCTAssertLessThan(styles[0].cycleDuration, GamingTextStyle.standard.cycleDuration)
        for (easier, harder) in zip(styles, styles.dropFirst()) {
            XCTAssertGreaterThan(easier.cycleDuration, harder.cycleDuration)
            XCTAssertLessThan(easier.saturation, harder.saturation)
        }
    }

    /// 点滅に見えないよう、色相は 1 秒あたり 3 周未満、脈動も 1 秒あたり 3 回未満にする
    func testTitleAnimationStaysBelowFlashThreshold() {
        for difficulty in Difficulty.allCases {
            let style = difficulty.confirmationTitleStyle(reduceMotion: false)
            XCTAssertLessThan(1 / style.cycleDuration, 3, "\(difficulty)")
            if let pulse = style.pulse {
                XCTAssertLessThan(1 / pulse.period, 3, "\(difficulty)")
            }
        }
    }

    /// 脈動は Hard・Expert、揺れは Expert だけ
    func testPulseAndShakeByDifficulty() {
        XCTAssertNil(Difficulty.easy.confirmationTitleStyle(reduceMotion: false).pulse)
        XCTAssertNil(Difficulty.normal.confirmationTitleStyle(reduceMotion: false).pulse)
        XCTAssertNotNil(Difficulty.hard.confirmationTitleStyle(reduceMotion: false).pulse)
        XCTAssertNotNil(Difficulty.expert.confirmationTitleStyle(reduceMotion: false).pulse)

        XCTAssertNil(Difficulty.easy.confirmationTitleStyle(reduceMotion: false).shake)
        XCTAssertNil(Difficulty.normal.confirmationTitleStyle(reduceMotion: false).shake)
        XCTAssertNil(Difficulty.hard.confirmationTitleStyle(reduceMotion: false).shake)
        XCTAssertNotNil(Difficulty.expert.confirmationTitleStyle(reduceMotion: false).shake)
    }

    /// Reduce Motion では脈動・揺れをせず、鮮やかさの差だけ残す（Q5）。回転は GamingHue.isAnimating で止まる
    func testReduceMotionKeepsOnlySaturation() {
        for difficulty in Difficulty.allCases {
            let reduced = difficulty.confirmationTitleStyle(reduceMotion: true)
            XCTAssertNil(reduced.pulse, "\(difficulty)")
            XCTAssertNil(reduced.shake, "\(difficulty)")
            XCTAssertEqual(reduced.saturation, difficulty.confirmationTitleStyle(reduceMotion: false).saturation, "\(difficulty)")
            XCTAssertEqual(reduced.scale(elapsed: 0.2), 1, "\(difficulty)")
            XCTAssertEqual(reduced.offset(elapsed: 0.2), 0, "\(difficulty)")
        }
        let saturations = difficultiesByLevel.map { $0.confirmationTitleStyle(reduceMotion: true).saturation }
        XCTAssertEqual(Set(saturations).count, saturations.count)
    }

    /// 脈動・揺れは変えた時刻（elapsed = 0）に元の大きさ・位置から始まり、決まった幅に収まる
    func testPulseAndShakeStartFromRestAndStayInRange() throws {
        let style = Difficulty.expert.confirmationTitleStyle(reduceMotion: false)
        let pulse = try XCTUnwrap(style.pulse)
        let shake = try XCTUnwrap(style.shake)
        XCTAssertEqual(style.scale(elapsed: 0), 1, accuracy: 1e-9)
        XCTAssertEqual(style.offset(elapsed: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(style.scale(elapsed: pulse.period / 2), 1 + pulse.amplitude, accuracy: 1e-9)
        XCTAssertEqual(style.offset(elapsed: shake.period / 4), shake.amplitude, accuracy: 1e-9)
        for elapsed in stride(from: 0.0, to: 3.0, by: 0.01) {
            XCTAssertGreaterThanOrEqual(style.scale(elapsed: elapsed), 1 - 1e-9)
            XCTAssertLessThanOrEqual(style.scale(elapsed: elapsed), 1 + pulse.amplitude + 1e-9)
            XCTAssertLessThanOrEqual(abs(style.offset(elapsed: elapsed)), shake.amplitude + 1e-9)
        }
    }
}
