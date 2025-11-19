//
//  PomodoroTimerView.swift
//  Flyt
//
//  ポモドーロタイマーのUI
//

import SwiftUI

struct PomodoroTimerView: View {
    @ObservedObject var manager = PomodoroManager.shared
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var syncManager = SyncManager.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 30) {
                Spacer()

                // 円形プログレスゲージ
                ZStack {
                    // 背景円
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 300, height: 300)

                    // 進捗円
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.getProgress()))
                        .stroke(
                            stateColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: manager.getProgress())

                    // 円の中央のコンテンツ
                    VStack(spacing: 8) {
                        // 状態表示
                        Text(stateText)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        // 時間表示
                        Text(manager.getTimeString())
                            .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(stateColor)

                        // セッション数と合計時間
                        if manager.sessionCount > 0 {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("\(manager.sessionCount)セッション")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(totalTimeString)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // コントロールボタン
                HStack(spacing: 25) {
                    // リセットボタン
                    Button(action: {
                        manager.reset()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
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
                                .fill(Color.white.opacity(0.3))
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
                                .fill(Color.white.opacity(0.2))
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

                // 同期ボタン（ログイン時のみ表示）
                if authManager.isAuthenticated {
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await syncManager.syncFromCloud()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14))
                                Text("取得")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .disabled(syncManager.isSyncing)

                        Button(action: {
                            let sessionCount = manager.sessionCount
                            syncManager.syncToCloud(sessionCount: sessionCount)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle")
                                    .font(.system(size: 14))
                                Text("送信")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .disabled(syncManager.isSyncing)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 設定ボタン（右上）
            Button(action: {
                WindowManager.shared.showSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
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
