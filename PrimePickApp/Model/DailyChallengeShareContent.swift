//
//  DailyChallengeShareContent.swift
//  PrimePickApp
//

import Foundation

/// デイリーの結果のシェアで渡す中身（Wordle 風）
///
/// 文と App Store のキャンペーンリンクは、共有シートに別々の項目として渡す。
/// 問題の数字は文に入れない（その日の答えを明かさない）。
struct DailyChallengeShareContent: Equatable {
    /// App Store のキャンペーンリンク。キャンペーン名（ct）は daily_share の 1 つに固定する
    static let appStoreURL = URL(string: "https://apps.apple.com/app/apple-store/id6502471694?pt=121319537&ct=daily_share&mt=8")!

    /// 通し番号（`#12`）
    let dayNumber: Int
    /// 日付（`2026-10-01`）。言語によらず同じ書式にする
    let dateText: String
    /// 10 問の正誤の並び（🟩🟥）
    let resultPattern: String
    let correctCount: Int
    let questionCount: Int
    /// 合計解答時間（小数第 1 位まで。結果画面と同じ表記）
    let totalSecondsText: String
    /// 連続日数
    let streak: Int

    /// 最後まで解いた日の結果から作る。途中でやめた日や、日付の読めない記録では nil
    init?(result: DailyChallengeResult) {
        let record = result.record
        guard record.isCompleted, let dayNumber = result.dayNumber else { return nil }
        self.dayNumber = dayNumber
        self.dateText = record.dayKey
        self.resultPattern = result.resultPattern
        self.correctCount = record.correctCount
        self.questionCount = record.results.count
        self.totalSecondsText = DailyChallengeResult.totalSecondsText(record.totalAnswerSeconds)
        self.streak = result.streak.current
    }

    /// 1 行目: アプリ名・通し番号・日付
    var headline: String {
        String(localized: "Prime Pick Daily Challenge #\(dayNumber) (\(dateText))")
    }

    /// 正解数と合計解答時間（`8/10 correct · 42.5 sec`）
    var scoreLine: String {
        String(localized: "\(correctCount)/\(questionCount) correct · \(totalSecondsText) sec")
    }

    /// 連続日数（`🔥 3-day streak`）
    var streakLine: String {
        String(localized: "🔥 \(streak)-day streak")
    }

    /// シェアの文。リンクは含めず、`appStoreURL` を別の項目として渡す
    var text: String {
        [headline, resultPattern, scoreLine, streakLine].joined(separator: "\n")
    }

    /// 共有シートに渡すリンク
    var url: URL { Self.appStoreURL }
}
