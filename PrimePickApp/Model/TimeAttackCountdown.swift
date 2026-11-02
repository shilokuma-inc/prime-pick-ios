//
//  TimeAttackCountdown.swift
//  PrimePickApp
//

import Foundation

/// タイムアタックの残り時間を、実時間（1 秒より細かい単位）で求める（Discussion #484）
///
/// `QuizSession` は残り時間を整数の秒で持ち、1 秒ごとに `.tick` で減らす。
/// その整数の残り秒と、最後にカウントダウンが進んだ時刻（`session.start()` を呼んだ時刻か、最後の `.tick` を受け取った時刻）から、
/// 今の時刻での残り時間を求める。quiz-kit を変えずに小数の表示とプログレスバーの滑らかな動きを出すため、アプリの側で計算する。
struct TimeAttackCountdown: Equatable {
    /// 1 秒の途中の経過として数える上限。1 秒以上経っても、整数の残り秒から 1 秒以上は減らさない
    ///
    /// バックグラウンドから戻ったときや Timer が遅れたときに一気に減らさず、次の `.tick` を待つ。
    static let maxElapsedWithinSecond: TimeInterval = 1.0.nextDown

    let gameMode: GameMode
    /// `QuizSession.remainingSeconds`。誤答のペナルティで減ったときもそのまま渡す
    let remainingSeconds: Int
    /// 最後にカウントダウンが進んだ時刻。まだ始めていない（撮影モードを含む）なら nil
    let lastAdvancedAt: Date?

    /// `date` の時点の残り時間（秒）
    ///
    /// 誤答のペナルティは整数の残り秒が減るだけで、1 秒の途中の経過はそのまま数える。
    /// まだ始めていないときと、残りが 0（タイムアップ）のときは整数の残り秒をそのまま返す。
    func remainingTime(at date: Date) -> TimeInterval {
        guard let lastAdvancedAt, remainingSeconds > 0 else {
            return TimeInterval(max(0, remainingSeconds))
        }
        let elapsed = min(max(0, date.timeIntervalSince(lastAdvancedAt)), Self.maxElapsedWithinSecond)
        return max(0, TimeInterval(remainingSeconds) - elapsed)
    }

    /// `date` の時点で、残り時間を小数 2 桁で表示するか
    func showsFractionalSeconds(at date: Date) -> Bool {
        gameMode.showsFractionalRemainingTime(remainingTime(at: date))
    }

    /// `date` の時点で画面に出す残り時間
    func displayValue(at date: Date) -> TimeAttackRemainingTimeDisplay {
        let remainingTime = remainingTime(at: date)
        guard gameMode.showsFractionalRemainingTime(remainingTime) else {
            return .wholeSeconds(remainingSeconds)
        }
        return .fractionalSeconds(TimeAttackRemainingTimeDisplay.fractionalText(for: remainingTime))
    }
}

/// 画面に出す残り時間
enum TimeAttackRemainingTimeDisplay: Equatable {
    /// 整数の秒（5 秒以上）。今までどおり `QuizSession.remainingSeconds` を出す
    case wholeSeconds(Int)
    /// 小数 2 桁の秒（5 秒未満）。例: `"4.99"`・`"4.90"`・`"0.00"`
    case fractionalSeconds(String)

    /// 残り時間を小数 2 桁の文字列にする
    ///
    /// 切り捨てる。四捨五入だと `4.995` 以上で `5.00` を出してから整数表示へ戻って見えるため。
    /// 小数点は端末の地域によらず `.` に固定する（依頼の例が `2.00秒` のため）。
    static func fractionalText(for remainingTime: TimeInterval) -> String {
        // `4.99 * 100` が `498.999…` になって 1 つ下に切り捨てないよう、ごくわずかに足してから切り捨てる
        let hundredths = Int((max(0, remainingTime) * 100 + 1e-6).rounded(.down))
        // 足した分でしきい値ちょうど（`5.00`）にならないよう、しきい値の直前で止める
        let clamped = min(hundredths, GameMode.timeAttackFractionalDisplayThresholdSeconds * 100 - 1)
        return String(format: "%d.%02d", clamped / 100, clamped % 100)
    }
}
