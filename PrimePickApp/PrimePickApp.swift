//
//  PrimePickApp.swift
//  PrimePickApp
//
//  Created by 村石 拓海 on 2024/04/11.
//

import SwiftUI

@main
struct PrimePickApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppTheme.userDefaultsKey) private var appTheme = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            MainView()
                // シートは別の presentation になり `.preferredColorScheme` が開いたままでは届かないため、
                // ウィンドウごと切り替えてシートとその遷移先にも即時に反映する。
                // 撮影モードでは端末やテーマ設定によらず同じ配色で撮る
                .background(
                    WindowUserInterfaceStyleView(
                        style: AppTheme.resolvedUserInterfaceStyle(
                            rawValue: appTheme,
                            screenshotColorScheme: ScreenshotDemo.colorScheme
                        )
                    )
                )
        }
    }
}

/// 配置先のウィンドウの `overrideUserInterfaceStyle` を設定する。ウィンドウに載った直後（起動時）と値の変更時に適用する
private struct WindowUserInterfaceStyleView: UIViewRepresentable {
    let style: UIUserInterfaceStyle

    func makeUIView(context: Context) -> StyleApplyingView {
        let view = StyleApplyingView()
        view.isUserInteractionEnabled = false
        view.style = style
        return view
    }

    func updateUIView(_ uiView: StyleApplyingView, context: Context) {
        uiView.style = style
    }

    final class StyleApplyingView: UIView {
        var style: UIUserInterfaceStyle = .unspecified {
            didSet { applyStyle() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            applyStyle()
        }

        private func applyStyle() {
            guard let window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
        }
    }
}
