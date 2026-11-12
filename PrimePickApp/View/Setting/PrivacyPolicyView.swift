//
//  PrivacyPolicyView.swift
//  PrimePickApp
//

import SwiftUI

/// 設定画面から開くプライバシーポリシー。公開済みのページを画面内の WebView で表示する
struct PrivacyPolicyView: View {
    static let url = URL(string: "https://shilokuma.jp/privacy/prime-pick/")

    var body: some View {
        if let url = Self.url {
            WebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
