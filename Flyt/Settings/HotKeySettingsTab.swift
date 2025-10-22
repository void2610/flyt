//
//  HotKeySettingsTab.swift
//  Flyt
//
//  ホットキー設定タブ
//

import SwiftUI

struct HotKeySettingsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("キーボードショートカット")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("メモウィンドウを開閉するキーボードショートカットを設定します")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HotKeyRecorderView()
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    HotKeySettingsTab()
}
