//
//  SettingsView.swift
//  Flyt
//
//  設定画面
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // タイトル
            Text("設定")
                .font(.title)
                .fontWeight(.bold)

            Divider()

            // ホットキー設定
            VStack(alignment: .leading, spacing: 8) {
                Text("キーボードショートカット")
                    .font(.headline)

                HotKeyRecorderView()
            }

            Divider()

            // アプリ情報
            VStack(alignment: .leading, spacing: 8) {
                Text("アプリ情報")
                    .font(.headline)

                HStack {
                    Text("version:")
                    Spacer()
                    Text("0.1.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Bundle ID:")
                    Spacer()
                    Text("void2610.Flyt")
                        .foregroundColor(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Spacer()

            // フッター
            HStack {
                Spacer()
                Text("© 2025 void2610")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    SettingsView()
}
