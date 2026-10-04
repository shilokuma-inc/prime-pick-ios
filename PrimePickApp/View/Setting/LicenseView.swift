//
//  LicenseView.swift
//  PrimePickApp
//

import LicenseList
import SwiftUI

/// 設定画面から開く、利用している OSS のライセンス一覧
struct LicenseView: View {
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            List {
                Section {
                    ForEach(Library.libraries, id: \.name) { library in
                        NavigationLink {
                            LicenseDetailView(library: library)
                        } label: {
                            Text(library.name)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.clear)
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// ライブラリ 1 件分のライセンス本文を表示する詳細画面
private struct LicenseDetailView: View {
    let library: Library

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let url = library.url {
                        Link(url.absoluteString, destination: url)
                            .font(.footnote)
                    }

                    if library.licenseBody.isEmpty {
                        Text("License text not found")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(library.licenseBody)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
            }
        }
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LicenseView()
    }
}
