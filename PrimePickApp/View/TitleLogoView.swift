//
//  TitleLogoView.swift
//  PrimePickApp
//

import SwiftUI

/// ホームのタイトル「Prime Pick」のロゴ
///
/// ロゴの中身（文字・書体・飾り）はこの View の中だけで決める。呼び出し側は虹の激しさだけを渡す
struct TitleLogoView: View {
    /// 呼び出し側が渡す虹の激しさ
    var style: GamingTextStyle = .standard

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        #if DEBUG
        if let candidate = TitleLogoCandidate.active {
            // iPad では大きくする（iPhone の幅に収まる大きさを 1 とする）
            TitleLogoCandidateView(candidate: candidate, style: style, scale: horizontalSizeClass == .regular ? 1.6 : 1)
        } else {
            standardLogo
        }
        #else
        standardLogo
        #endif
    }

    private var standardLogo: some View {
        Text("Prime Pick")
            .gamingText(style: style)
            .font(.custom("Helvetica Neue", size: 60))
            .fontWeight(.bold)
    }
}

#Preview {
    TitleLogoView()
}

#Preview("Expert の確認のカード") {
    TitleLogoView(style: Difficulty.expert.confirmationTitleStyle(reduceMotion: false))
}
