//
//  PomodoroTimerView.swift
//  Flyt
//
//  ポモドーロタイマーのUI
//

import SwiftUI

struct PomodoroTimerView: View {
    @ObservedObject var manager = PomodoroManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 状態表示
            Text(stateText)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(stateColor)
                .padding(.bottom, 20)

            // 時間表示
            Text(manager.getTimeString())
                .font(.system(size: 120, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(stateColor)
                .padding(.bottom, 30)

            // セッション数
            if manager.sessionCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("完了: \(manager.sessionCount)セッション")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            } else {
                Spacer()
                    .frame(height: 62)
            }

            // コントロールボタン
            HStack(spacing: 20) {
                // リセットボタン
                Button(action: {
                    manager.reset()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 28))
                        Text("リセット")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .frame(width: 80)
                }
                .buttonStyle(.plain)
                .opacity(manager.state == .idle ? 0.3 : 1.0)
                .disabled(manager.state == .idle)

                // 開始/一時停止ボタン
                Button(action: {
                    if manager.isRunning {
                        manager.pause()
                    } else {
                        manager.start()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 36))
                        Text(manager.isRunning ? "停止" : "開始")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(stateColor)
                    .frame(width: 100)
                }
                .buttonStyle(.plain)

                // スキップボタン
                Button(action: {
                    manager.skipToNext()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                        Text("スキップ")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .frame(width: 80)
                }
                .buttonStyle(.plain)
                .opacity(manager.state == .idle ? 0.3 : 1.0)
                .disabled(manager.state == .idle)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // 状態に応じたテキスト
    private var stateText: String {
        switch manager.state {
        case .idle:
            return "準備完了"
        case .working:
            return "🍅 作業中"
        case .resting:
            return "☕️ 休憩中"
        }
    }

    // 状態に応じた色
    private var stateColor: Color {
        switch manager.state {
        case .idle:
            return .secondary
        case .working:
            return .red
        case .resting:
            return .green
        }
    }
}

#Preview {
    PomodoroTimerView()
        .frame(width: 600, height: 500)
}
