//
//  FirebaseAnalytics.swift
//  PrimePickApp
//

import FirebaseAnalytics

final class FirebaseAnalytics {
    func sendAnalyticsScreen(screenName: String) {
        // 撮影モードの起動は利用の計測に含めない
        guard !ScreenshotDemo.isEnabled else { return }
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName
            ]
        )
    }

    func sendAnswer(_ event: AnswerAnalyticsEvent) {
        guard !ScreenshotDemo.isEnabled else { return }
        Analytics.logEvent(AnswerAnalyticsEvent.name, parameters: event.parameters)
    }

    func sendQuizStart(_ event: QuizStartAnalyticsEvent) {
        guard !ScreenshotDemo.isEnabled else { return }
        Analytics.logEvent(QuizStartAnalyticsEvent.name, parameters: event.parameters)
    }

    func sendDailyChallenge(_ event: DailyChallengeAnalyticsEvent) {
        guard !ScreenshotDemo.isEnabled else { return }
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}
