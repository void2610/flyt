//
//  HotKeySettingsTab.swift
//  Flyt
//
//  ホットキー設定タブ
//

import SwiftUI

struct HotKeySettingsTab: View {
    var body: some View {
        Form {
            Section {
                Text("キーボードショートカット")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                Text("メモウィンドウを開閉するキーボードショートカットを設定します")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)

                HotKeyRecorderView()
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    HotKeySettingsTab()
}
