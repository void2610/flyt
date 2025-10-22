//
//  HotEdgeSettingsTab.swift
//  Flyt
//
//  ホットエッジ設定タブ
//

import SwiftUI

struct HotEdgeSettingsTab: View {
    var body: some View {
        Form {
            Section {
                Text("ホットエッジ")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                Text("画面の端にマウスを移動してメモウィンドウを開閉します")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)

                HotCornerSettingsView()
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    HotEdgeSettingsTab()
}
