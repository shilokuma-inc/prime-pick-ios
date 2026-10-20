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
}
