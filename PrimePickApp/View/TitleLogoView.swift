//
//  TitleLogoView.swift
//  PrimePickApp
//

import SwiftUI

/// ホームのタイトル「Prime Pick」のロゴ
///
/// ロゴの中身（文字・書体・飾り）はこの View の中だけで決める。呼び出し側は虹の激しさだけを渡す
struct TitleLogoView: View {
    /// 虹の激しさ。確認のカードを出している間は難易度に応じて激しくする（Discussion #394 Q3）
    var style: GamingTextStyle = .standard

    var body: some View {
        Text("Prime Pick")
            .gamingText(style: style)
            .font(.custom("Helvetica Neue", size: 60))
            .fontWeight(.bold)
    }
}

#Preview {
    TitleLogoView()
}
