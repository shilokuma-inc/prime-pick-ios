//
//  GameMode.swift
//  PrimePickApp
//

import SwiftUI

/// クイズの進行ルール
enum GameMode: Hashable, Identifiable, CaseIterable {
    /// タイムアタックの誤答で減らす残り時間（秒）。制限時間の長さによらず固定
    static let timeAttackMissTimePenaltySeconds = 2

    /// タイムアタックの誤答後に入力を受け付けない時間（秒）
    static let timeAttackMissInputLockDuration: TimeInterval = 0.5

    /// タイムアタックで残り時間を赤くして急かし始める秒数
    static let timeAttackFinalCountdownSeconds = 5

    /// 10 問固定・時間無制限
    case practice
    /// 制限時間内に何問正解できるかを競うモード
    case timeAttack(TimeAttackDuration)
    /// デイリーチャレンジ。全員が同じ日に同じ 10 問を 1 日 1 回解く（Discussion #181）
    ///
    /// 時間無制限・ミニ解説ありは練習と同じ。評価は正解数と合計解答時間だけなので、スコアとコンボは出さない。
    case dailyChallenge

    /// モード選択に並べる選択肢。タイムアタックは制限時間ごとに 1 つ並ぶ
    ///
    /// デイリーはタイトル画面のカードから始めるため、ここには含めない。
    static var allCases: [GameMode] {
        [.practice] + TimeAttackDuration.allCases.map(GameMode.timeAttack)
    }

    var id: String {
        switch self {
        case .practice:
            return "practice"
        case .timeAttack(let duration):
            return "timeAttack_\(duration.seconds)"
        case .dailyChallenge:
            return "dailyChallenge"
        }
    }

    /// タイムアタックかどうか
    var isTimeAttack: Bool {
        switch self {
        case .practice, .dailyChallenge:
            return false
        case .timeAttack:
            return true
        }
    }

    /// 解き終えたら出題画面の上に結果（`QuizResultView`）を重ねるか
    ///
    /// デイリーはスコアを出さない専用の結果画面（`DailyChallengeResultView`）に切り替えるため重ねない。
    var showsQuizResult: Bool {
        self != .dailyChallenge
    }

    /// プレイ中にコンボ（連続正解数）を見せるか。デイリーはスコアを競わないので出さない（Discussion #181 Q2）
    var showsCombo: Bool {
        self != .dailyChallenge
    }

    /// 出題中に戻るとき確認を挟むか
    ///
    /// デイリーは始めた時点で今日の挑戦権を使い、やめるとそこで結果が確定するため、誤って抜けないよう確認する（Discussion #181 Q3）。
    var confirmsBeforeQuitting: Bool {
        self == .dailyChallenge
    }

    /// 解答直後にミニ解説を表示するか
    ///
    /// タイムアタックではテンポを崩さないよう表示せず、練習モードだけで表示する（Discussion #138 / PR #152 で確認済み）。
    var showsAnswerExplanation: Bool {
        !isTimeAttack
    }

    /// スコアの計算ルール。誤答の減点と速度ボーナスの条件はタイムアタックだけに適用する
    var scoringRule: ScoringRule {
        isTimeAttack ? .timeAttack : .practice
    }

    /// 誤答で減らす残り時間（秒）。練習モードは制限時間が無いので 0
    var missTimePenaltySeconds: Int {
        isTimeAttack ? Self.timeAttackMissTimePenaltySeconds : 0
    }

    /// 誤答後に入力を受け付けない時間（秒）。練習モードはロックしないので 0
    var missInputLockDuration: TimeInterval {
        isTimeAttack ? Self.timeAttackMissInputLockDuration : 0
    }

    /// 誤答のペナルティを反映した残り時間。0 以下になる場合は 0（即タイムアップ）を返す
    func remainingSecondsAfterMiss(from remainingSeconds: Int) -> Int {
        max(0, remainingSeconds - missTimePenaltySeconds)
    }

    /// 残り時間が終盤（残り 5 秒以下）か。練習モードは制限時間が無いので常に false
    ///
    /// 0 秒はタイムアップでリザルトを出すため含めない。
    func isInFinalCountdown(remainingSeconds: Int) -> Bool {
        isTimeAttack && (1...Self.timeAttackFinalCountdownSeconds).contains(remainingSeconds)
    }

    /// 画面に表示するモード名
    var localizedTitle: LocalizedStringKey {
        switch self {
        case .practice:
            return "Practice"
        case .timeAttack(let duration):
            return duration.localizedTitle
        case .dailyChallenge:
            return "Daily Challenge"
        }
    }

    /// 制限時間（秒）。練習モードは制限なしのため nil を返す
    var timeLimitSeconds: Int? {
        switch self {
        case .practice, .dailyChallenge:
            return nil
        case .timeAttack(let duration):
            return duration.seconds
        }
    }
}

/// タイムアタックの制限時間
enum TimeAttackDuration: Int, CaseIterable, Identifiable {
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case sixtySeconds = 60

    var id: Int { rawValue }

    /// 制限時間（秒）
    var seconds: Int { rawValue }

    /// 画面に表示する制限時間名
    var localizedTitle: LocalizedStringKey {
        "\(seconds) seconds"
    }
}
