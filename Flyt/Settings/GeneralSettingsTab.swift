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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("一般設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                // アプリ終了ボタン
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("アプリを終了")
                }
                .focused($isQuitButtonFocused)
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
