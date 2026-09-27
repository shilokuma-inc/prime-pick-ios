//
//  FirebaseAnalytics.swift
//  PrimePickApp
//

import FirebaseAnalytics

final class FirebaseAnalytics {
    func sendAnalyticsScreen(screenName: String) {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: screenName
            ]
        )
    }

    func sendAnswer(_ event: AnswerAnalyticsEvent) {
        Analytics.logEvent(AnswerAnalyticsEvent.name, parameters: event.parameters)
    }
}
