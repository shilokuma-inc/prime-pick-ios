//
//  AnalyticsScreen.swift
//  PrimePickApp
//

import SwiftUI

/// Analytics に送信する画面名
enum AnalyticsScreen: String {
    case main = "Main"
    case howToPlay = "HowToPlay"
    case quiz = "Quiz"
    case quizResult = "QuizResult"
}

private struct AnalyticsScreenModifier: ViewModifier {
    let screen: AnalyticsScreen
    private let analytics = FirebaseAnalytics()

    func body(content: Content) -> some View {
        content
            .onAppear {
                analytics.sendAnalyticsScreen(screenName: screen.rawValue)
            }
    }
}

extension View {
    /// 表示時に screen_view イベントを送信する
    func sendAnalyticsScreen(_ screen: AnalyticsScreen) -> some View {
        modifier(AnalyticsScreenModifier(screen: screen))
    }
}
