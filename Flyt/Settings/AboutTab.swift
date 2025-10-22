//
//  AboutTab.swift
//  Flyt
//
//  アプリ情報タブ
//

import SwiftUI

struct AboutTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // アプリアイコン（代わりにSFシンボル）
                Image(systemName: "text.book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)

                // アプリ名
                Text("Flyt")
                    .font(.title)
                    .fontWeight(.bold)

                // バージョン情報
                VStack(spacing: 8) {
                    HStack {
                        Text("Version:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("0.1.0")
                    }

                    HStack {
                        Text("Bundle ID:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("void2610.Flyt")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding(.horizontal, 20)

                Divider()
                    .padding(.vertical, 8)

                // 説明
                Text("フルスクリーンアプリの上にも表示できるmacOS用メモアプリ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // コピーライト
                Text("© 2025 void2610")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding(30)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    AboutTab()
}
