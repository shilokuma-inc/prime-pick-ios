//
//  ScreenshotDemo.swift
//  PrimePickApp
//

import SwiftUI

/// App Store 用スクリーンショットの撮影モード（Issue #201）。
///
/// 起動引数 `-screenshot-demo` で有効になり、`-screenshot-scene <名前>` で最初に開く画面を選ぶ。
/// 撮影は `Tools/capture_screenshots.sh` が言語・画面ごとにアプリを起動し直して行う。
/// 有効なあいだは、画面が落ち着くのを待って撮れるよう、繰り返すアニメーションとタイマーを止め、
/// 出題を固定し、Analytics を送らない。通常の起動では何も変えない。
enum ScreenshotDemo {
    /// 撮影する画面。並び順は `AppStore/screenshots.json` で決める
    enum Scene: String {
        /// タイトル画面
        case main
        /// 練習モードの出題中（ミニ解説とコンボを表示）
        case quiz
        /// タイムアタックの出題中（残り時間を表示）
        case timeAttack = "time-attack"
        /// 結果画面
        case result
        /// 遊び方のシート
        case howToPlay = "how-to-play"
    }

    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-screenshot-demo")

    /// 起動引数は UserDefaults の引数ドメインに入るので、`-screenshot-scene quiz` をここで読める
    static let scene: Scene? = isEnabled
        ? UserDefaults.standard.string(forKey: "screenshot-scene").flatMap(Scene.init(rawValue:))
        : nil

    /// 撮影モードで固定する配色。端末やテーマ設定によらず同じ見た目で撮る
    static var colorScheme: ColorScheme? {
        isEnabled ? .light : nil
    }

    /// 撮影モードで出題に使う乱数のシード。撮り直しても同じ数が出るようにする
    static let randomSeed: UInt64 = 2_357_111_317

    /// 起動時に `NavigationStack` へ積んでおく画面
    static var initialPath: [QuizSetting] {
        quiz.map { [$0.setting] } ?? []
    }

    /// 出題中・結果の画面に流し込む進行状態。該当しない画面では nil
    static var quiz: ScreenshotDemoQuiz? {
        switch scene {
        case .quiz:
            return .practice
        case .timeAttack:
            return .timeAttack
        case .result:
            return .result
        case .main, .howToPlay, nil:
            return nil
        }
    }
}

/// 撮影モードで `QuizView` に流し込む、クイズの進行状態。
///
/// 出題する数は言語に依らないので、ja / en で同じ値を使う。
/// 素数と合成数を混ぜ、ミニ解説と復習一覧に素因数分解（`323 = 17 × 19`）が出るようにしている。
struct ScreenshotDemoQuiz {
    /// 1 問あたりの解答にかかったことにする秒数。速度ボーナスの計算に使う
    static let elapsedTime: TimeInterval = 1.8

    let setting: QuizSetting
    /// 出題する数（この順）
    let numbers: [Int]
    /// 解答済みの問題数。出題中の画面では `numbers[answeredCount]` を表示する
    let answeredCount: Int
    /// 間違えたことにする問題（0 始まりの出題順）
    let missedIndices: Set<Int>
    /// タイムアタックの残り秒数
    let remainingSeconds: Int
    /// 結果画面を表示するか
    let isFinished: Bool

    /// 練習モード（ふつう）の 4 問目。直前の `323 = 17 × 19` のミニ解説と 3 コンボを表示する
    static let practice = ScreenshotDemoQuiz(
        setting: QuizSetting(difficulty: .normal, gameMode: .practice, range: nil, questionCount: .ten),
        numbers: practiceNumbers,
        answeredCount: 3,
        missedIndices: [],
        remainingSeconds: 0,
        isFinished: false
    )

    /// タイムアタック 60 秒（むずかしい）の 7 問目。残り 42 秒・6 コンボ
    ///
    /// むずかしいは 2・3・5 の倍数を出題しないので、その条件に合う数だけを並べる
    static let timeAttack = ScreenshotDemoQuiz(
        setting: QuizSetting(difficulty: .hard, gameMode: .timeAttack(.sixtySeconds), range: nil, questionCount: .ten),
        numbers: [101, 143, 221, 289, 307, 391, 541, 629, 787, 899],
        answeredCount: 6,
        missedIndices: [],
        remainingSeconds: 42,
        isFinished: false
    )

    /// 練習モード（ふつう）を解き終えた結果。10 問中 9 問正解で、復習一覧に `561 = 3 × 11 × 17` が 1 件出る
    static let result = ScreenshotDemoQuiz(
        setting: QuizSetting(difficulty: .normal, gameMode: .practice, range: nil, questionCount: .ten),
        numbers: practiceNumbers,
        answeredCount: 10,
        missedIndices: [4],
        remainingSeconds: 0,
        isFinished: true
    )

    /// 練習モード（100 〜 999）で出題する数。素数と合成数を交互に近い割合で混ぜている
    private static let practiceNumbers = [139, 221, 323, 397, 561, 613, 667, 719, 851, 997]

    /// `QuizView` が持つ出題データ
    var quizData: [QuizEntity] {
        numbers.enumerated().map { index, number in
            QuizEntity(
                quizId: index + 1,
                number: number,
                isCorrect: PrimeFactorization.isPrime(number),
                difficulty: setting.difficulty,
                range: setting.range ?? setting.difficulty.defaultRange
            )
        }
    }

    /// 解答済みの問題の記録。`missedIndices` の問題だけ正解と逆の解答にする
    var answerRecords: [QuizAnswerRecord] {
        quizData.prefix(answeredCount).enumerated().map { index, quiz in
            QuizAnswerRecord(
                id: quiz.quizId,
                number: quiz.number,
                isPrime: quiz.isCorrect,
                answeredPrime: missedIndices.contains(index) ? !quiz.isCorrect : quiz.isCorrect
            )
        }
    }

    /// 解答済みの問題を反映したスコア。実際のプレイと同じ計算式で求める
    var scoreCalculator: ScoreCalculator {
        var calculator = ScoreCalculator()
        for record in answerRecords {
            calculator.submit(
                isCorrect: record.isAnswerCorrect,
                difficulty: setting.difficulty,
                elapsedTime: Self.elapsedTime
            )
        }
        return calculator
    }

    /// 表示中の問題（0 始まり）。解き終えたあとは最後の問題のまま結果画面を重ねる
    var quizNumber: Int {
        isFinished ? max(0, answeredCount - 1) : answeredCount
    }

    /// 直前に解答した数のミニ解説。まだ解答していなければ nil
    var lastAnsweredExplanation: NumberExplanation? {
        answerRecords.last.map { NumberExplanation(number: $0.number) }
    }
}
