//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var hue: Double = 0
    /// 難易度ボタンで積まれるクイズ画面と、カードから開くデイリーチャレンジ。撮影モードでは最初から出題中・結果の画面を積んでおく
    @State private var path = NavigationPath(ScreenshotDemo.initialPath)
    /// 「今日のチャレンジ」カードの内容。表示のたびに記録から読み直す
    @State private var dailyChallengeCard: DailyChallengeCardState?
    /// How to Play・設定・記録の画面が同時に出ないよう、表示中のシートを 1 つの状態で持つ。
    /// 撮影モードでは最初から遊び方のシートを開いておく
    @State private var presentedSheet: MainSheet? = ScreenshotDemo.scene == .howToPlay ? .howToPlay : nil
    @State private var gameMode: GameMode = .practice
    @State private var selectedQuestionCount: QuizQuestionCount = .default
    /// 確認のカードを出しているタイムアタックの設定。nil ならカードを出していない（Discussion #394）
    @State private var pendingTimeAttack: QuizSetting?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                // 選んでいるモードの色を背景にうっすら重ね、モードで雰囲気を変える（Discussion #330）。
                // タイムアタックの確認のカードを出している間は、難易度の色にして難しいほど濃くする（Discussion #394 Q2）
                ModeAmbientBackground(
                    colors: pendingTimeAttack.map { $0.difficulty.ambientColors(for: colorScheme) } ?? gameMode.themeColors,
                    style: pendingTimeAttack.map { $0.difficulty.confirmationGlowStyle(reduceMotion: reduceMotion) } ?? .standard
                )
                .ignoresSafeArea()

                // 難易度ボタンが 4 つになり、iPhone SE などの背の低い画面ではデイリーのカードから「遊び方」までが収まらない。
                // 収まらないときだけスクロールさせる（大きい画面の見た目は変えない）
                ViewThatFits(in: .vertical) {
                    homeContent

                    ScrollView {
                        homeContent
                    }
                }
                // 確認のカードを出している間は、後ろのボタンを押させず、VoiceOver にも読ませない
                .disabled(isConfirmingTimeAttack)
                .accessibilityHidden(isConfirmingTimeAttack)

                if let pendingTimeAttack {
                    timeAttackStartConfirmation(for: pendingTimeAttack)
                }
            }
            .animation(Self.confirmationAnimation, value: pendingTimeAttack)
            .navigationDestination(for: DailyChallengeRoute.self) { _ in
                DailyChallengeView(onPlayTimeAttack: playTimeAttackFromDailyChallenge)
            }
            .navigationDestination(for: QuizSetting.self) { setting in
                QuizView(
                    difficulty: setting.difficulty,
                    gameMode: setting.gameMode,
                    questionCount: setting.questionCount,
                    source: setting.source
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Group {
                        recordsButton
                        settingButton
                    }
                    .disabled(isConfirmingTimeAttack)
                    .accessibilityHidden(isConfirmingTimeAttack)
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .howToPlay:
                    HowToPlayView()
                case .setting:
                    SettingView()
                case .records:
                    TimeAttackRecordsView()
                }
            }
            .sendAnalyticsScreen(.main)
            // デイリーから戻ったとき・日付が変わって前面に戻ったときに、カードの状態とストリークを読み直す
            .onAppear(perform: refreshDailyChallengeCard)
            .onChange(of: path.count) { _, count in
                if count == 0 {
                    refreshDailyChallengeCard()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshDailyChallengeCard()
                }
            }
        }
    }
}

/// メイン画面から開くシート
private enum MainSheet: Identifiable {
    case howToPlay
    case setting
    /// タイムアタックの記録（Discussion #270）
    case records

    var id: Self { self }
}

/// カードからデイリーチャレンジへ遷移するときの `NavigationPath` の値
struct DailyChallengeRoute: Hashable {}

/// タイトル画面の背景に重ねる、選んでいるモードの色の柔らかい光（Discussion #330）
///
/// 左上にモードの色の 1 色目、右下に 2 色目を置き、画面の内側に向かって消えるようにぼかす。
/// 文字やボタンの読みやすさを損なわないよう薄くとどめ、モードを切り替えたときは前の光とクロスフェードさせる。
/// タイムアタックの確認のカードを出している間だけ、`style` で濃くしたり脈動させたりする（Discussion #394 Q2）。
/// 脈動しないときは時刻による描き直しを止めるので、撮影モードでも画面は落ち着く。
struct ModeAmbientBackground: View {
    /// 光の色。`GameMode.themeColors`、または確認のカードの表示中は難易度の色
    let colors: [Color]
    /// 光の濃さと脈動
    var style: AmbientGlowStyle = .standard

    @Environment(\.colorScheme) private var colorScheme

    /// 光の中心の濃さ。ダークは暗い背景の上で色が浮きやすいので、ライトより薄くする
    static func glowOpacity(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? 0.25 : 0.3
    }

    /// 切り替えのクロスフェードの長さ（秒）
    static let crossFadeDuration: TimeInterval = 0.6

    var body: some View {
        ZStack {
            // 色が変わったときだけ前の光と入れ替える。タイムアタックの制限時間どうしは色が同じなので変わらない
            TimelineView(.animation(paused: style.pulse == nil)) { context in
                glow(opacity: style.glowOpacity(base: Self.glowOpacity(for: colorScheme), at: context.date))
            }
            .id(colors)
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: Self.crossFadeDuration), value: colors)
        .animation(.easeInOut(duration: Self.crossFadeDuration), value: style)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func glow(opacity: Double) -> some View {
        GeometryReader { proxy in
            // 画面の長い辺の 6 割まで広げ、2 つの光が画面の中ほどで薄く重なるようにする
            let radius = max(proxy.size.width, proxy.size.height) * 0.6
            ZStack {
                light(colors.first, opacity: opacity, center: .topLeading, radius: radius)
                light(colors.last, opacity: opacity, center: .bottomTrailing, radius: radius)
            }
        }
    }

    private func light(_ color: Color?, opacity: Double, center: UnitPoint, radius: CGFloat) -> some View {
        let color = color ?? .clear
        return RadialGradient(
            colors: [color.opacity(opacity), color.opacity(0)],
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

/// 背景の光の濃さと脈動（Discussion #394 Q2）
struct AmbientGlowStyle: Equatable {
    /// 光の脈動。濃さを `1 - depth` 倍から 1 倍の間でゆっくり往復させる
    struct Pulse: Equatable {
        /// 1 往復の秒数。点滅に見えないよう、1 秒あたり 3 回未満（0.34 秒より長く）にする
        let period: TimeInterval
        /// 濃さを下げる割合（0〜1）
        let depth: Double
    }

    /// 光の中心の濃さを、モードの光（`ModeAmbientBackground.glowOpacity`）の何倍にするか
    let intensity: Double
    /// nil なら脈動しない
    let pulse: Pulse?

    /// モードの光（今までの見た目）
    static let standard = AmbientGlowStyle(intensity: 1, pulse: nil)

    /// `date` の時点の光の中心の濃さ。1 を超えないようにする
    func glowOpacity(base: Double, at date: Date) -> Double {
        min(1, base * intensity * pulseScale(at: date))
    }

    /// 脈動による濃さの倍率（`1 - depth` 以上 1 以下）。脈動しないときは 1
    func pulseScale(at date: Date) -> Double {
        guard let pulse, pulse.period > 0 else { return 1 }
        let phase = date.timeIntervalSinceReferenceDate / pulse.period
        // 時刻 0 で 1（いちばん濃い）から始まる余弦の波
        let wave = (1 + cos(2 * .pi * phase)) / 2
        return 1 - pulse.depth * (1 - wave)
    }
}

extension Difficulty {
    /// 確認のカードを出している間の背景の光の色
    ///
    /// エキスパートの 2 色目（黒）はダークの背景に溶けて見えないので、ダークでは難易度ボタンの側面と同じ紺にする。
    func ambientColors(for colorScheme: ColorScheme) -> [Color] {
        switch (self, colorScheme) {
        case (.expert, .dark):
            return [Color.indigo, gameButtonSideColor(for: colorScheme) ?? Color.indigo]
        default:
            return gradientColors
        }
    }

    /// 確認のカードを出している間の背景の光の濃さと脈動。難しいほど濃くし、Hard・Expert では脈動させる
    ///
    /// Reduce Motion のときは脈動させず、色と濃さだけで難易度を伝える（Discussion #394 Q5）。
    func confirmationGlowStyle(reduceMotion: Bool) -> AmbientGlowStyle {
        let intensity: Double
        let pulse: AmbientGlowStyle.Pulse?
        switch self {
        case .easy:
            intensity = 1.4
            pulse = nil
        case .normal:
            intensity = 1.7
            pulse = nil
        case .hard:
            intensity = 2.0
            pulse = AmbientGlowStyle.Pulse(period: 2.4, depth: 0.3)
        case .expert:
            intensity = 2.4
            pulse = AmbientGlowStyle.Pulse(period: 1.6, depth: 0.4)
        }
        return AmbientGlowStyle(intensity: intensity, pulse: reduceMotion ? nil : pulse)
    }
}

private extension MainView {
    /// タイトル・設定・難易度ボタン・遊び方のボタン
    var homeContent: some View {
        VStack {
            dailyChallengeCardLink

            Spacer()
            
            // 確認のカードを出している間は、難易度に応じて虹を激しくする（Discussion #394 Q3）
            Text("Prime Pick")
                .gamingText(
                    style: pendingTimeAttack.map { $0.difficulty.confirmationTitleStyle(reduceMotion: reduceMotion) }
                        ?? .standard
                )
                .font(.custom("Helvetica Neue", size: 60))
                .fontWeight(.bold)
            
            
            Spacer()

            SelectQuizSettingView(
                gameMode: $gameMode,
                selectedQuestionCount: $selectedQuestionCount
            )

            SelectDifficultyButtonView(
                gameMode: gameMode,
                questionCount: selectedQuestionCount,
                onRequestStartConfirmation: { pendingTimeAttack = $0 }
            )

            howToPlayButton
            
            Spacer()
        }
    }

    /// 最上段の「今日のチャレンジ」カード
    ///
    /// 撮影モードでは出さない。App Store のスクリーンショット（Issue #201 で決めたホーム画面）の見た目を変えないため。
    @ViewBuilder
    var dailyChallengeCardLink: some View {
        if !ScreenshotDemo.isEnabled, let dailyChallengeCard {
            NavigationLink(value: DailyChallengeRoute()) {
                DailyChallengeCardView(state: dailyChallengeCard)
            }
            .buttonStyle(
                GameButtonStyle(
                    appearance: .neutral(
                        shape: .roundedRectangle(cornerRadius: DailyChallengeCardView.cornerRadius),
                        depth: Self.homeSecondaryButtonDepth
                    )
                )
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    var isConfirmingTimeAttack: Bool {
        pendingTimeAttack != nil
    }

    /// タイムアタックを始めるか確かめるカード。後ろのタイトル画面が見えるよう、薄く暗くするだけにとどめる
    ///
    /// カードの外のタップでは閉じない（後ろの暗い面がタップを受け止める）。閉じるのは「やめる」とエスケープのジェスチャーだけ
    @ViewBuilder
    func timeAttackStartConfirmation(for setting: QuizSetting) -> some View {
        Color.black.opacity(Self.confirmationScrimOpacity)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .transition(.opacity)

        TimeAttackStartConfirmationView(
            setting: setting,
            onStart: {
                pendingTimeAttack = nil
                path.append(setting)
            },
            onCancel: {
                pendingTimeAttack = nil
            }
        )
        // Reduce Motion のときは拡大させず、フェードだけにする
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.9)))
    }

    /// 確認のカードの後ろを暗くする黒の不透明度
    static let confirmationScrimOpacity: Double = 0.2

    /// 確認のカードを出し入れするアニメーション
    static let confirmationAnimation: Animation = .easeOut(duration: 0.2)

    /// デイリーの結果画面から、タイトルで選んでいる設定のタイムアタックを始める
    ///
    /// すぐには始めず、タイトル画面に戻ってから確認のカードを出す（Discussion #394 Q4）。
    /// 背景と虹の演出はタイトル画面にしかないため。「スタート」で出題画面へ進み、戻るとタイトルに戻る。「やめる」ならタイトル画面に残る。
    /// 設定の `source`（`.dailyResult`）はカードを挟んでもそのまま `QuizView` に渡すので、`quiz_start` の source は変わらない。
    func playTimeAttackFromDailyChallenge() {
        let setting = DailyChallengeResult.timeAttackSetting(
            selectedGameMode: gameMode,
            selectedQuestionCount: selectedQuestionCount
        )
        path = NavigationPath()
        pendingTimeAttack = setting
    }

    func refreshDailyChallengeCard() {
        dailyChallengeCard = DailyChallengeCardState(
            records: UserDefaultsDailyChallengeStore().allRecords(),
            today: DailyChallengeDay.today()
        )
    }

    /// 設定の左に置くタイムアタックの記録の入口
    ///
    /// 撮影モードでは出さない。App Store のスクリーンショットの見た目を変えないため（デイリーのカードと同じ扱い）。
    @ViewBuilder
    var recordsButton: some View {
        if !ScreenshotDemo.isEnabled {
            Button {
                presentedSheet = .records
            } label: {
                Image(systemName: "trophy")
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Time Attack Records")
        }
    }

    var settingButton: some View {
        Button {
            presentedSheet = .setting
        } label: {
            Image(systemName: "gearshape")
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Settings")
    }

    var howToPlayButton: some View {
        Button {
            presentedSheet = .howToPlay
        } label: {
            Label("How to Play", systemImage: "questionmark.circle")
                .appFont(.heading(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.4), lineWidth: 2)
                )
        }
        .buttonStyle(GameButtonStyle(appearance: .neutral(shape: .capsule, depth: Self.homeSecondaryButtonDepth)))
    }

    /// 遊び方のボタンと今日のチャレンジのカードの厚み。背の低い画面でホームの高さを圧迫しないよう、難易度ボタンより薄くする
    static let homeSecondaryButtonDepth: CGFloat = 4
}

extension Difficulty {
    public var gradientColors: [Color] {
        switch self {
        case .easy:
            return [Color.green, Color.yellow]
        case .normal:
            return [Color.purple, Color.blue]
        case .hard:
            return [Color.red, Color.purple]
        case .expert:
            return [Color.indigo, Color.black]
        }
    }
}
#Preview {
    MainView()
}
