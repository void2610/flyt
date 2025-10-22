//
//  AccessibilitySettingsTab.swift
//  Flyt
//
//  アクセシビリティ設定タブ
//

import SwiftUI
import AppKit

struct AccessibilitySettingsTab: View {
    @State private var hasAccessibilityPermission = AXIsProcessTrusted()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("アクセシビリティ")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("グローバルキーボードショートカットとホットエッジを使用するには、アクセシビリティ権限が必要です")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 権限状態の表示
                HStack {
                    Text("権限の状態:")
                        .font(.subheadline)
                    Spacer()
                    if hasAccessibilityPermission {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("許可済み")
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("未許可")
                                .foregroundColor(.red)
                        }
                    }
                }

                Divider()

                // システム設定を開くボタン
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        openAccessibilitySettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("システム設定を開く")
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Text("システム設定 > プライバシーとセキュリティ > アクセシビリティ で Flyt を有効にしてください")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // 権限チェックボタン
                Button(action: {
                    hasAccessibilityPermission = AXIsProcessTrusted()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("権限状態を再確認")
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            hasAccessibilityPermission = AXIsProcessTrusted()
        }
    }

    // アクセシビリティ設定を開く
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AccessibilitySettingsTab()
}
