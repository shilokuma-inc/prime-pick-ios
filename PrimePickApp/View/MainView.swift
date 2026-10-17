//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @Environment(\.scenePhase) private var scenePhase
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

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                // 選んでいるモードの色を背景にうっすら重ね、モードで雰囲気を変える（Discussion #330）
                ModeAmbientBackground(colors: gameMode.themeColors)
                    .ignoresSafeArea()

                // 難易度ボタンが 4 つになり、iPhone SE などの背の低い画面ではデイリーのカードから「遊び方」までが収まらない。
                // 収まらないときだけスクロールさせる（大きい画面の見た目は変えない）
                ViewThatFits(in: .vertical) {
                    homeContent

                    ScrollView {
                        homeContent
                    }
                }
            }
            // バナーの分だけ下を空け、ホームのボタンに重ねない（背の低い画面では上のスクロールで逃がす）
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerView(placement: .home)
            }
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
                    recordsButton
                    settingButton
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
/// 動き続けるアニメーションは使わないので、撮影モードでも画面は落ち着く。
struct ModeAmbientBackground: View {
    /// 光の色。`GameMode.themeColors`
    let colors: [Color]

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
            glow
                .id(colors)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: Self.crossFadeDuration), value: colors)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var glow: some View {
        GeometryReader { proxy in
            // 画面の長い辺の 6 割まで広げ、2 つの光が画面の中ほどで薄く重なるようにする
            let radius = max(proxy.size.width, proxy.size.height) * 0.6
            ZStack {
                light(colors.first, center: .topLeading, radius: radius)
                light(colors.last, center: .bottomTrailing, radius: radius)
            }
        }
    }

    private func light(_ color: Color?, center: UnitPoint, radius: CGFloat) -> some View {
        let color = color ?? .clear
        return RadialGradient(
            colors: [color.opacity(Self.glowOpacity(for: colorScheme)), color.opacity(0)],
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

private extension MainView {
    /// タイトル・設定・難易度ボタン・遊び方のボタン
    var homeContent: some View {
        VStack {
            dailyChallengeCardLink

            Spacer()
            
            Text("Prime Pick")
                .gamingText()
                .font(.custom("Helvetica Neue", size: 60))
                .fontWeight(.bold)
            
            
            Spacer()

            SelectQuizSettingView(
                gameMode: $gameMode,
                selectedQuestionCount: $selectedQuestionCount
            )

            SelectDifficultyButtonView(
                gameMode: gameMode,
                questionCount: selectedQuestionCount
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

    /// デイリーの結果画面から、タイトルで選んでいる設定のタイムアタックを始める
    ///
    /// デイリーの画面をタイムアタックに置き換える（タイムアタックから戻るとタイトルに戻る）。
    func playTimeAttackFromDailyChallenge() {
        let setting = DailyChallengeResult.timeAttackSetting(
            selectedGameMode: gameMode,
            selectedQuestionCount: selectedQuestionCount
        )
        var newPath = NavigationPath()
        newPath.append(setting)
        path = newPath
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
                .font(.system(size: 18, weight: .bold, design: .rounded))
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
