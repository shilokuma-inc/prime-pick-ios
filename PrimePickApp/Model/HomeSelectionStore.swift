//
//  HomeSelectionStore.swift
//  PrimePickApp
//

import Foundation

/// タイトル画面で最後に選んだゲームモードと問題数の保存先（#545）
///
/// アプリを起動し直しても、前回の選択のまま遊び始められるようにする。難易度はボタンを押すとすぐ始まるので保存しない。
/// 撮影モードでは読まず書かない。App Store のスクリーンショットのホーム画面が、端末に残った選択で変わらないようにするため。
struct HomeSelectionStore {
    /// ゲームモード（`GameMode.id`）のキー
    static let gameModeKey = "homeSelection.gameMode"
    /// 問題数（`QuizQuestionCount.rawValue`）のキー
    static let questionCountKey = "homeSelection.questionCount"

    /// 保存していない・読めないときのゲームモード（今までの起動直後と同じ）
    static let defaultGameMode: GameMode = .practice

    private let userDefaults: UserDefaults
    private let isScreenshotDemo: Bool

    init(userDefaults: UserDefaults = .standard, isScreenshotDemo: Bool = ScreenshotDemo.isEnabled) {
        self.userDefaults = userDefaults
        self.isScreenshotDemo = isScreenshotDemo
    }

    /// 前回選んだゲームモード。選べないモード（デイリーなど）や知らない値なら既定の練習にする
    var gameMode: GameMode {
        guard !isScreenshotDemo, let id = userDefaults.string(forKey: Self.gameModeKey) else {
            return Self.defaultGameMode
        }
        return GameMode.allCases.first { $0.id == id } ?? Self.defaultGameMode
    }

    /// 前回選んだ問題数。知らない値なら既定の 10 問にする
    var questionCount: QuizQuestionCount {
        guard !isScreenshotDemo,
              let rawValue = userDefaults.object(forKey: Self.questionCountKey) as? Int,
              let count = QuizQuestionCount(rawValue: rawValue)
        else {
            return .default
        }
        return count
    }

    func save(gameMode: GameMode) {
        // デイリーはタイトル画面のモード選択に並ばないので、選択として残さない
        guard !isScreenshotDemo, GameMode.allCases.contains(gameMode) else { return }
        userDefaults.set(gameMode.id, forKey: Self.gameModeKey)
    }

    func save(questionCount: QuizQuestionCount) {
        guard !isScreenshotDemo else { return }
        userDefaults.set(questionCount.rawValue, forKey: Self.questionCountKey)
    }
}
