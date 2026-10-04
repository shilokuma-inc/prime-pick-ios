//
//  ContentView.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

struct MainView: View {
    @State private var hue: Double = 0
    /// How to Play と設定画面が同時に出ないよう、表示中のシートを 1 つの状態で持つ
    @State private var presentedSheet: MainSheet?
    @State private var gameMode: GameMode = .practice
    /// `nil` は「おまかせ」＝ 難易度ごとの既定レンジを使う
    @State private var selectedRange: QuizRange?
    @State private var selectedQuestionCount: QuizQuestionCount = .default

    var body: some View {
        NavigationStack {
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
                                   
struct LazyView<Content: View>: View {
   let content: () -> Content
   
   init(_ content: @autoclosure @escaping () -> Content) {
       self.content = content
   }
   
   var body: Content {
       content()
   }
}

#Preview {
    MainView()
}
