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
    /// How to Play と設定画面が同時に出ないよう、表示中のシートを 1 つの状態で持つ。
    /// 撮影モードでは最初から遊び方のシートを開いておく
    @State private var presentedSheet: MainSheet? = ScreenshotDemo.scene == .howToPlay ? .howToPlay : nil
    @State private var gameMode: GameMode = .practice
    @State private var selectedQuestionCount: QuizQuestionCount = .default

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground
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
                ToolbarItem(placement: .topBarTrailing) {
                    settingButton
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .howToPlay:
                    HowToPlayView()
                case .setting:
                    SettingView()
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

    var id: Self { self }
}

/// カードからデイリーチャレンジへ遷移するときの `NavigationPath` の値
struct DailyChallengeRoute: Hashable {}

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
            .buttonStyle(.plain)
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
                        .stroke(Color.primary.opacity(0.4), lineWidth: 2)
                )
        }
    }
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
