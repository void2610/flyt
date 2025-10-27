//
//  HotEdgeSettingsTab.swift
//  Flyt
//
//  ホットエッジ設定タブ
//

import SwiftUI

struct HotEdgeSettingsTab: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ホットエッジ")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("画面の端にマウスを移動してタイマーウィンドウを開閉します")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HotEdgeSettingsView()
            }
            .padding(50)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    HotEdgeSettingsTab()
}
