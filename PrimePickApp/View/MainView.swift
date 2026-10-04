//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @State private var hue: Double = 0
    /// 難易度ボタンで積まれるクイズ画面。撮影モードでは最初から出題中・結果の画面を積んでおく
    @State private var path: [QuizSetting] = ScreenshotDemo.initialPath
    /// How to Play と設定画面が同時に出ないよう、表示中のシートを 1 つの状態で持つ。
    /// 撮影モードでは最初から遊び方のシートを開いておく
    @State private var presentedSheet: MainSheet? = ScreenshotDemo.scene == .howToPlay ? .howToPlay : nil
    @State private var gameMode: GameMode = .practice
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジを使う
    @State private var selectedRange: QuizRange?
    @State private var selectedQuestionCount: QuizQuestionCount = .default

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Text("Prime Pick")
                        .gamingText()
                        .font(.custom("Helvetica Neue", size: 60))
                        .fontWeight(.bold)
                    
                    
                    Spacer()

                    SelectQuizSettingView(
                        gameMode: $gameMode,
                        selectedRange: $selectedRange,
                        selectedQuestionCount: $selectedQuestionCount
                    )

                    SelectDifficultyButtonView(
                        gameMode: gameMode,
                        selectedRange: selectedRange,
                        questionCount: selectedQuestionCount
                    )

                    howToPlayButton
                    
                    Spacer()
                }
            }
            .navigationDestination(for: QuizSetting.self) { setting in
                QuizView(
                    difficulty: setting.difficulty,
                    gameMode: setting.gameMode,
                    range: setting.range,
                    questionCount: setting.questionCount
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
        }
    }
}

/// メイン画面から開くシート
private enum MainSheet: Identifiable {
    case howToPlay
    case setting

    var id: Self { self }
}

private extension MainView {
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
        }
    }
}
#Preview {
    MainView()
}
