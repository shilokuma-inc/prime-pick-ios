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
    /// プログレスバーを描き直す最短の間隔（秒）。毎秒 30 回
    ///
    /// バーはプレイの間ずっと動くので、端末の最大のフレームレート（ProMotion で毎秒 120 回）ではなく、
    /// 電池と発熱を抑えつつ段差が見えない間隔にする。15 秒の制限時間でも 1 回の描き直しで減るのは 1pt 未満。
    static let progressUpdateInterval: TimeInterval = 1.0 / 30

    let gameMode: GameMode
    /// `QuizSession.remainingSeconds`。誤答のペナルティで減ったときもそのまま渡す
    let remainingSeconds: Int
    /// 最後にカウントダウンが進んだ時刻。まだ始めていない（撮影モードを含む）なら nil
    let lastAdvancedAt: Date?

    /// `date` の時点の残り時間（秒）
    ///
    /// 1 秒の途中の経過は `0 ..< 1` 秒に収め、整数の残り秒の 1 秒手前より下には減らさない。
    /// バックグラウンドから戻ったときや Timer が遅れたときに一気に減らさず、次の `.tick` を待つ。
    /// 誤答のペナルティは整数の残り秒が減るだけで、1 秒の途中の経過はそのまま数える。
    /// まだ始めていないときと、残りが 0（タイムアップ）のときは整数の残り秒をそのまま返す。
    func remainingTime(at date: Date) -> TimeInterval {
        guard let lastAdvancedAt, remainingSeconds > 0 else {
            return TimeInterval(max(0, remainingSeconds))
        }
        let elapsed = max(0, date.timeIntervalSince(lastAdvancedAt))
        // 経過の上限を `1.0.nextDown` にしても、2 以上から引くと丸めで 1 秒手前ちょうどになるため、結果の側に下限を付ける
        let floor = TimeInterval(remainingSeconds - 1).nextUp
        return max(TimeInterval(remainingSeconds) - elapsed, floor)
    }

    /// 残り時間を毎フレーム描き直すか
    ///
    /// 整数の残り秒がしきい値以下なら、実時間の残りはしきい値以下で、ほぼずっと小数で表示する。
    /// まだ始めていない（撮影モードを含む）ときと、タイムアップの後は描き直さない。
    var updatesEveryFrame: Bool {
        gameMode.isTimeAttack
            && lastAdvancedAt != nil
            && (1...GameMode.timeAttackFractionalDisplayThresholdSeconds).contains(remainingSeconds)
    }

    /// プログレスバーを実時間に合わせて描き直し続けるか
    ///
    /// まだ始めていない（撮影モードを含む）ときと、タイムアップの後は止める。
    var updatesProgressContinuously: Bool {
        gameMode.isTimeAttack && lastAdvancedAt != nil && remainingSeconds > 0
    }

    /// `date` の時点のプログレスバーの値（残り時間 ÷ 制限時間、`0...1`）
    ///
    /// 練習・デイリーは制限時間が無いので、今までどおり僅かに進んだ見た目（`0.01`）にする。
    func progress(at date: Date) -> Double {
        guard let timeLimitSeconds = gameMode.timeLimitSeconds, timeLimitSeconds > 0 else {
            return 0.01
        }
        return min(1, max(0, remainingTime(at: date) / TimeInterval(timeLimitSeconds)))
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
