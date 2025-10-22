//
//  SettingsView.swift
//  Flyt
//
//  設定画面（横並びタブバー）
//

import SwiftUI

// タブの種類を定義
enum SettingsTab: String, CaseIterable {
    case general = "一般"
    case hotkey = "ホットキー"
    case hotedge = "ホットエッジ"
    case accessibility = "アクセシビリティ"
    case about = "情報"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .hotkey: return "keyboard"
        case .hotedge: return "hand.point.up"
        case .accessibility: return "accessibility"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        VStack(spacing: 0) {
            // 横並びタブバー
            HStack(spacing: 10) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                            Text(tab.rawValue)
                                .font(.system(size: 9))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 70, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.white.opacity(0.1) : Color(NSColor.windowBackgroundColor).opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // 選択されたタブのコンテンツ
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsTab()
                case .hotkey:
                    HotKeySettingsTab()
                case .hotedge:
                    HotEdgeSettingsTab()
                case .accessibility:
                    AccessibilitySettingsTab()
                case .about:
                    AboutTab()
                }
            }
        }
        .frame(width: 600, height: 450)
    }
}

#Preview {
    SettingsView()
}
