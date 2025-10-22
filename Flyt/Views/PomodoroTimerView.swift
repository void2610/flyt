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
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()

            // 状態表示
            Text(stateText)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)

            // 時間表示
            Text(manager.getTimeString())
                .font(.system(size: 100, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(stateColor)
                .padding(.bottom, 12)

            // セッション数と合計時間
            if manager.sessionCount > 0 {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("完了: \(manager.sessionCount)セッション")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("合計: \(totalTimeString)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            } else {
                Spacer()
                    .frame(height: 36)
            }

            // コントロールボタン
            HStack(spacing: 25) {
                // リセットボタン
                Button(action: {
                    manager.reset()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 50, height: 50)
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .focusable(false)
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
                    ZStack {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 70, height: 70)
                        Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(.plain)
                .focusable(false)

                // スキップボタン
                Button(action: {
                    manager.skipToNext()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 50, height: 50)
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .focusable(false)
                .opacity(manager.state == .idle ? 0.3 : 1.0)
                .disabled(manager.state == .idle)
            }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

            // 設定ボタン（右上）
            Button(action: {
                WindowManager.shared.showSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .padding(16)
        }
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

    // 合計時間の文字列（作業時間 × セッション数）
    private var totalTimeString: String {
        let totalMinutes = manager.workDurationMinutes * manager.sessionCount
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }
}

#Preview {
    PomodoroTimerView()
        .frame(width: 600, height: 500)
}
