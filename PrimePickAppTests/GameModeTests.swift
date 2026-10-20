//
//  GameModeTests.swift
//  PrimePickAppTests
//

import SwiftUI
import XCTest
@testable import PrimePickApp

final class GameModeTests: XCTestCase {

    // MARK: - 制限時間

    func testPracticeHasNoTimeLimit() {
        XCTAssertNil(GameMode.practice.timeLimitSeconds)
        XCTAssertFalse(GameMode.practice.isTimeAttack)
    }

    func testTimeAttackReturnsSelectedDuration() {
        XCTAssertEqual(GameMode.timeAttack(.fifteenSeconds).timeLimitSeconds, 15)
        XCTAssertEqual(GameMode.timeAttack(.thirtySeconds).timeLimitSeconds, 30)
        XCTAssertEqual(GameMode.timeAttack(.sixtySeconds).timeLimitSeconds, 60)
    }

    func testTimeAttackIsTimeAttackForEveryDuration() {
        for duration in TimeAttackDuration.allCases {
            XCTAssertTrue(GameMode.timeAttack(duration).isTimeAttack)
        }
    }

    // MARK: - ミニ解説

    func testOnlyTimeAttackConfirmsBeforeStarting() {
        XCTAssertFalse(GameMode.practice.confirmsBeforeStarting)
        XCTAssertFalse(GameMode.dailyChallenge.confirmsBeforeStarting)
        for duration in TimeAttackDuration.allCases {
            XCTAssertTrue(GameMode.timeAttack(duration).confirmsBeforeStarting, "duration=\(duration.seconds)")
        }
    }

    func testAnswerExplanationIsShownOnlyInPractice() {
        XCTAssertTrue(GameMode.practice.showsAnswerExplanation)
        for duration in TimeAttackDuration.allCases {
            XCTAssertFalse(GameMode.timeAttack(duration).showsAnswerExplanation)
        }
    }

    // MARK: - スコアルール

    func testScoringRuleIsTimeAttackOnlyForTimeAttack() {
        XCTAssertEqual(GameMode.practice.scoringRule, .practice)
        for duration in TimeAttackDuration.allCases {
            XCTAssertEqual(GameMode.timeAttack(duration).scoringRule, .timeAttack)
        }
    }

    // MARK: - 誤答のペナルティ

    func testMissPenaltyAppliesOnlyToTimeAttack() {
        XCTAssertEqual(GameMode.practice.missTimePenaltySeconds, 0)
        XCTAssertEqual(GameMode.practice.missInputLockDuration, 0)
        for duration in TimeAttackDuration.allCases {
            // 制限時間の長さによらず固定
            XCTAssertEqual(GameMode.timeAttack(duration).missTimePenaltySeconds, 2)
            XCTAssertEqual(GameMode.timeAttack(duration).missInputLockDuration, 0.5, accuracy: 0.0001)
        }
    }

    func testRemainingSecondsAfterMissSubtractsTwoSeconds() {
        let mode = GameMode.timeAttack(.thirtySeconds)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 30), 28)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 3), 1)
    }

    /// 残り 2 秒以下で誤答したら 0（即タイムアップ）になり、負にはならない
    func testRemainingSecondsAfterMissStopsAtZero() {
        let mode = GameMode.timeAttack(.fifteenSeconds)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 2), 0)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 1), 0)
        XCTAssertEqual(mode.remainingSecondsAfterMiss(from: 0), 0)
    }

    func testPracticeRemainingSecondsIsUnchangedByMiss() {
        XCTAssertEqual(GameMode.practice.remainingSecondsAfterMiss(from: 10), 10)
    }

    // MARK: - 残り 5 秒の演出

    func testFinalCountdownStartsAtFiveSeconds() {
        for duration in TimeAttackDuration.allCases {
            let mode = GameMode.timeAttack(duration)
            XCTAssertFalse(mode.isInFinalCountdown(remainingSeconds: 6))
            XCTAssertTrue(mode.isInFinalCountdown(remainingSeconds: 5))
            XCTAssertTrue(mode.isInFinalCountdown(remainingSeconds: 1))
            // 0 秒はタイムアップ
            XCTAssertFalse(mode.isInFinalCountdown(remainingSeconds: 0))
        }
    }

    func testPracticeHasNoFinalCountdown() {
        XCTAssertFalse(GameMode.practice.isInFinalCountdown(remainingSeconds: 3))
    }

    // MARK: - モード選択の並び

    func testAllCasesIsPracticeFollowedByDurationsInAscendingOrder() {
        XCTAssertEqual(
            GameMode.allCases,
            [
                .practice,
                .timeAttack(.fifteenSeconds),
                .timeAttack(.thirtySeconds),
                .timeAttack(.sixtySeconds)
            ]
        )
    }

    func testIdIsUniqueForEveryCase() {
        let ids = GameMode.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: - モードの色

    func testPracticeAndTimeAttackHaveDifferentThemeColors() {
        XCTAssertEqual(GameMode.practice.themeColors, GameMode.practiceThemeColors)
        XCTAssertNotEqual(GameMode.practiceThemeColors, GameMode.timeAttackThemeColors)
    }

    /// タイムアタックは制限時間によらず同じ色
    func testTimeAttackThemeColorsAreSameForEveryDuration() {
        for duration in TimeAttackDuration.allCases {
            XCTAssertEqual(GameMode.timeAttack(duration).themeColors, GameMode.timeAttackThemeColors)
        }
    }

    /// デイリーはモード選択に並ばないが、時間無制限で練習と同じ進め方なので練習の色
    func testDailyChallengeUsesPracticeThemeColors() {
        XCTAssertEqual(GameMode.dailyChallenge.themeColors, GameMode.practiceThemeColors)
    }

    /// 選択中のカプセルは 2 色のグラデーションで塗る
    func testThemeColorsAreTwoColorGradient() {
        for mode in GameMode.allCases + [.dailyChallenge] {
            XCTAssertEqual(mode.themeColors.count, 2, "\(mode.id)")
            XCTAssertNotEqual(mode.themeColors.first, mode.themeColors.last, "\(mode.id)")
        }
    }

    /// 練習は緑〜水色、タイムアタックはオレンジ〜赤の系統にする（Discussion #330 Q3）。タイトル画面の背景の光もこの色を使う
    func testThemeColorsStayInEachModeHueRange() {
        for color in GameMode.practiceThemeColors {
            let hue = Self.hueDegrees(of: color)
            XCTAssertTrue((90...210).contains(hue), "練習の色相 \(hue)")
        }
        for color in GameMode.timeAttackThemeColors {
            let hue = Self.hueDegrees(of: color)
            XCTAssertTrue(hue >= 330 || hue <= 45, "タイムアタックの色相 \(hue)")
        }
    }

    /// 色相（0〜360 度）
    private static func hueDegrees(of color: Color) -> Double {
        var hue: CGFloat = 0
        UIColor(color).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return Double(hue) * 360
    }

    // MARK: - タイトル画面の背景

    /// 背景に重ねるモードの色の光は、文字やボタンの読みやすさを損なわない「若干」の濃さにとどめる（Discussion #330）
    func testAmbientBackgroundGlowIsSubtle() {
        for colorScheme in [ColorScheme.light, .dark] {
            let opacity = ModeAmbientBackground.glowOpacity(for: colorScheme)
            XCTAssertGreaterThan(opacity, 0, "\(colorScheme)")
            XCTAssertLessThanOrEqual(opacity, 0.3, "\(colorScheme)")
        }
    }

    /// ダークは暗い背景の上で色が浮きやすいので、ライトより薄くする
    func testAmbientBackgroundGlowIsFainterInDarkMode() {
        XCTAssertLessThan(
            ModeAmbientBackground.glowOpacity(for: .dark),
            ModeAmbientBackground.glowOpacity(for: .light)
        )
    }

    // MARK: - 確認のカードの表示中の背景の光（Discussion #394 Q2）

    /// 今までの光（カードを出していないとき）は濃さを変えず、脈動もしない
    func testStandardGlowKeepsModeOpacity() {
        let date = Date(timeIntervalSinceReferenceDate: 0.7)
        XCTAssertNil(AmbientGlowStyle.standard.pulse)
        XCTAssertEqual(AmbientGlowStyle.standard.glowOpacity(base: 0.3, at: date), 0.3, accuracy: 1e-9)
    }

    /// 難しいほど光を濃くする
    func testConfirmationGlowGetsStrongerWithDifficulty() {
        let order: [Difficulty] = [.easy, .normal, .hard, .expert]
        for reduceMotion in [false, true] {
            let intensities = order.map { $0.confirmationGlowStyle(reduceMotion: reduceMotion).intensity }
            XCTAssertGreaterThan(intensities[0], AmbientGlowStyle.standard.intensity, "reduceMotion=\(reduceMotion)")
            for (easier, harder) in zip(intensities, intensities.dropFirst()) {
                XCTAssertLessThan(easier, harder, "reduceMotion=\(reduceMotion)")
            }
        }
    }

    /// 脈動させるのは Hard・Expert だけ
    func testOnlyHardAndExpertGlowPulses() {
        XCTAssertNil(Difficulty.easy.confirmationGlowStyle(reduceMotion: false).pulse)
        XCTAssertNil(Difficulty.normal.confirmationGlowStyle(reduceMotion: false).pulse)
        XCTAssertNotNil(Difficulty.hard.confirmationGlowStyle(reduceMotion: false).pulse)
        XCTAssertNotNil(Difficulty.expert.confirmationGlowStyle(reduceMotion: false).pulse)
    }

    /// Reduce Motion では脈動させず、濃さは変えない（Discussion #394 Q5）
    func testReduceMotionStopsGlowPulseButKeepsIntensity() {
        for difficulty in Difficulty.allCases {
            let reduced = difficulty.confirmationGlowStyle(reduceMotion: true)
            XCTAssertNil(reduced.pulse, "\(difficulty)")
            XCTAssertEqual(reduced.intensity, difficulty.confirmationGlowStyle(reduceMotion: false).intensity, "\(difficulty)")
        }
    }

    /// 脈動は点滅に見えないよう、1 秒あたり 3 回未満にする。Expert のほうが Hard より速い
    func testGlowPulseIsSlowEnough() throws {
        let hard = try XCTUnwrap(Difficulty.hard.confirmationGlowStyle(reduceMotion: false).pulse)
        let expert = try XCTUnwrap(Difficulty.expert.confirmationGlowStyle(reduceMotion: false).pulse)
        for pulse in [hard, expert] {
            XCTAssertLessThan(1 / pulse.period, 3)
            XCTAssertGreaterThan(pulse.depth, 0)
            XCTAssertLessThan(pulse.depth, 1)
        }
        XCTAssertLessThan(expert.period, hard.period)
    }

    /// 脈動の倍率は 1 - depth から 1 の間を、周期どおりに往復する
    func testGlowPulseScaleFollowsTime() {
        let style = AmbientGlowStyle(intensity: 2, pulse: AmbientGlowStyle.Pulse(period: 2, depth: 0.4))
        let cases: [(seconds: TimeInterval, scale: Double)] = [(0, 1), (0.5, 0.8), (1, 0.6), (1.5, 0.8), (2, 1)]
        for (seconds, scale) in cases {
            XCTAssertEqual(
                style.pulseScale(at: Date(timeIntervalSinceReferenceDate: seconds)), scale,
                accuracy: 1e-9, "seconds=\(seconds)"
            )
        }
        XCTAssertEqual(style.glowOpacity(base: 0.3, at: Date(timeIntervalSinceReferenceDate: 1)), 0.36, accuracy: 1e-9)
    }

    /// どの難易度・外観でも、光の中心の濃さは 1 を超えず、脈動で消えきらない
    func testConfirmationGlowOpacityStaysInRange() {
        for difficulty in Difficulty.allCases {
            for colorScheme in [ColorScheme.light, .dark] {
                let style = difficulty.confirmationGlowStyle(reduceMotion: false)
                for seconds in stride(from: 0.0, to: 5.0, by: 0.1) {
                    let opacity = style.glowOpacity(
                        base: ModeAmbientBackground.glowOpacity(for: colorScheme),
                        at: Date(timeIntervalSinceReferenceDate: seconds)
                    )
                    XCTAssertGreaterThan(opacity, ModeAmbientBackground.glowOpacity(for: colorScheme), "\(difficulty) \(colorScheme)")
                    XCTAssertLessThanOrEqual(opacity, 1, "\(difficulty) \(colorScheme)")
                }
            }
        }
    }

    /// 背景の光の色は難易度の色。Expert のダークだけ、背景に溶ける黒を紺に替える
    func testConfirmationAmbientColors() {
        for difficulty in Difficulty.allCases {
            XCTAssertEqual(difficulty.ambientColors(for: .light), difficulty.gradientColors, "\(difficulty)")
        }
        for difficulty in [Difficulty.easy, .normal, .hard] {
            XCTAssertEqual(difficulty.ambientColors(for: .dark), difficulty.gradientColors, "\(difficulty)")
        }
        let expertDark = Difficulty.expert.ambientColors(for: .dark)
        XCTAssertEqual(expertDark.count, 2)
        XCTAssertFalse(expertDark.contains(Color.black))
    }
}
