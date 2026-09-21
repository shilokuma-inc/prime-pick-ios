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
}
