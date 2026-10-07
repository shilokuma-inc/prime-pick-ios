//
//  WebView.swift
//  PrimePickApp
//

import SwiftUI
import WebKit

/// 指定した URL を画面内で表示する `WKWebView` のラッパー
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    // 生成時に読み込むため、更新時は何もしない（同じ URL の再読み込みを防ぐ）
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
