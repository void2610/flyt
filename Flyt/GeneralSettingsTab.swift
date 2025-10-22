//
//  GeneralSettingsTab.swift
//  Flyt
//
//  一般設定タブ
//

import SwiftUI

struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            Section {
                Text("一般設定")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 8)

                // 将来の拡張用プレースホルダー
                Text("現在設定項目はありません")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    GeneralSettingsTab()
}
