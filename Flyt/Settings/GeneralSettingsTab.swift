//
//  GeneralSettingsTab.swift
//  Flyt
//
//  一般設定タブ
//

import SwiftUI

struct GeneralSettingsTab: View {
    @FocusState private var isQuitButtonFocused: Bool

    var body: some View {
        Form {
            Section {
                Text("一般設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                // アプリ終了ボタン
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("アプリを終了")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .focused($isQuitButtonFocused)
                .padding(.vertical, 10)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            // ビューが表示されたらボタンにフォーカスを当てる
            isQuitButtonFocused = true
        }
    }
}

#Preview {
    GeneralSettingsTab()
}
