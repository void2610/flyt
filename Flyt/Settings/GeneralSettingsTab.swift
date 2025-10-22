//
//  GeneralSettingsTab.swift
//  Flyt
//
//  一般設定タブ
//

import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var pomodoroManager = PomodoroManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ポモドーロ設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                // 作業時間設定
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.red)
                        .font(.title3)
                    Text("作業時間")
                        .font(.headline)
                    Spacer()
                    Stepper(
                        "\(pomodoroManager.workDurationMinutes)分",
                        value: $pomodoroManager.workDurationMinutes,
                        in: 1...120
                    )
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )

                // 休憩時間設定
                HStack {
                    Image(systemName: "cup.and.saucer")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("休憩時間")
                        .font(.headline)
                    Spacer()
                    Stepper(
                        "\(pomodoroManager.restDurationMinutes)分",
                        value: $pomodoroManager.restDurationMinutes,
                        in: 1...60
                    )
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )

                Divider()
                    .padding(.vertical, 8)

                // 統計情報
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日の統計")
                        .font(.headline)

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("完了セッション:")
                        Spacer()
                        Text("\(pomodoroManager.sessionCount)")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )

                Divider()
                    .padding(.vertical, 8)

                // リセットボタン
                Button(action: {
                    pomodoroManager.reset()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("タイマーをリセット")
                    }
                }
                .buttonStyle(.bordered)

                // アプリ終了ボタン
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("アプリを終了")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(30)
            .frame(maxWidth: 450)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    GeneralSettingsTab()
}
