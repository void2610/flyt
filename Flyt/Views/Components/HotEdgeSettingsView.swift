//
//  HotEdgeSettingsView.swift
//  Flyt
//
//  ホットエッジ設定のビュー
//

import SwiftUI

struct HotEdgeSettingsView: View {
    @ObservedObject var manager = HotEdgeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 有効/無効トグル
            Toggle("ホットエッジを有効にする", isOn: Binding(
                get: { manager.isEnabled },
                set: { newValue in
                    manager.updateSettings(edge: manager.selectedEdge, enabled: newValue)
                }
            ))

            if manager.isEnabled {
                // エッジ選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("トリガーする辺:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("", selection: Binding(
                        get: { manager.selectedEdge },
                        set: { newValue in
                            manager.updateSettings(edge: newValue, enabled: manager.isEnabled)
                        }
                    )) {
                        ForEach(HotEdge.allCases, id: \.self) { edge in
                            Text(edge.rawValue).tag(edge)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)

                    // 視覚的なプレビュー
                    HotEdgePreview(selectedEdge: manager.selectedEdge)
                        .frame(height: 120)
                        .padding(.top, 8)
                }

                Divider()
                    .padding(.vertical, 4)

                // エッジ判定幅の設定
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("判定幅:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(manager.edgeThreshold)) px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("狭い")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { Double(manager.edgeThreshold) },
                            set: { manager.updateEdgeThreshold(CGFloat($0)) }
                        ), in: 1...10, step: 1)
                        Text("広い")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // トリガー遅延時間の設定
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("反応速度:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f 秒", manager.triggerDelay))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("速い")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { manager.triggerDelay },
                            set: { manager.updateTriggerDelay($0) }
                        ), in: 0.1...1.0, step: 0.1)
                        Text("遅い")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// ホットエッジの視覚的なプレビュー
struct HotEdgePreview: View {
    let selectedEdge: HotEdge

    var body: some View {
        ZStack {
            // スクリーンを表す矩形
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )

            // 4つの辺にインジケーターを配置
            VStack(spacing: 0) {
                // 上辺
                EdgeIndicator(isActive: selectedEdge == .top, isHorizontal: true)
                    .frame(height: 4)

                Spacer()

                HStack(spacing: 0) {
                    // 左辺
                    EdgeIndicator(isActive: selectedEdge == .left, isHorizontal: false)
                        .frame(width: 4)

                    Spacer()

                    // 右辺
                    EdgeIndicator(isActive: selectedEdge == .right, isHorizontal: false)
                        .frame(width: 4)
                }

                Spacer()

                // 下辺
                EdgeIndicator(isActive: selectedEdge == .bottom, isHorizontal: true)
                    .frame(height: 4)
            }
            .padding(8)
        }
    }
}

// エッジインジケーター
struct EdgeIndicator: View {
    let isActive: Bool
    let isHorizontal: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 1)
            )
    }
}

#Preview {
    HotEdgeSettingsView()
        .padding()
        .frame(width: 400)
}
