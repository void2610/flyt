//
//  GeneralSettingsTab.swift
//  Flyt
//
//  一般設定タブ
//

import SwiftUI
import ColorSelector

struct GeneralSettingsTab: View {
    @ObservedObject var pomodoroManager = PomodoroManager.shared
    @ObservedObject var windowManager = WindowManager.shared
    @State private var workText: String = ""
    @State private var restText: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case work
        case rest
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("ポモドーロ設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                // 統計情報
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("今日の統計")
                            .font(.headline)
                    }

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

                // 作業時間と休憩時間設定
                VStack(alignment: .leading, spacing: 12) {
                    // 作業時間設定
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text("作業時間")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("", text: $workText)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 40)
                                .focused($focusedField, equals: .work)
                                .onSubmit {
                                    updateWorkDuration()
                                }
                                .onChange(of: focusedField) { oldValue, newValue in
                                    if oldValue == .work && newValue != .work {
                                        updateWorkDuration()
                                    }
                                }
                            Text("分")
                                .foregroundColor(.secondary)
                        }
                    }

                    // 休憩時間設定
                    HStack {
                        Image(systemName: "cup.and.saucer")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("休憩時間")
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("", text: $restText)
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 40)
                                .focused($focusedField, equals: .rest)
                                .onSubmit {
                                    updateRestDuration()
                                }
                                .onChange(of: focusedField) { oldValue, newValue in
                                    if oldValue == .rest && newValue != .rest {
                                        updateRestDuration()
                                    }
                                }
                            Text("分")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )
                .onAppear {
                    workText = "\(pomodoroManager.workDurationMinutes)"
                    restText = "\(pomodoroManager.restDurationMinutes)"
                }

                Divider()
                    .padding(.vertical, 8)

                // 背景のぼかし強度設定
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("背景のぼかし強度")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(windowManager.windowBlurStrength * 100))%")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $windowManager.windowBlurStrength, in: 0.0...1.0, step: 0.05)
                        .padding(.horizontal, 4)

                    Text("背景のぼかし効果の強さを調整します")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "square.fill.on.square.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("ウィンドウの不透明度")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(windowManager.windowOpacity * 100))%")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $windowManager.windowOpacity, in: 0.0...1.0, step: 0.05)
                        .padding(.horizontal, 4)

                    Text("ウィンドウ全体の不透明度を調整します")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // オーバーレイの色設定
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("オーバーレイの色")
                            .font(.headline)
                        Spacer()
                        ColorSelector(selection: $windowManager.overlayColor)
                            .frame(width: 200)
                    }

                    Text("オーバーレイの色を調整します")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )

                Divider()
                    .padding(.vertical, 8)

                HStack(spacing: 20) {
                    // リセットボタン
                    Button(action: {
                        pomodoroManager.reset()
                        pomodoroManager.resetSessionCount()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("タイマーをリセット")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)

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
            }
            .padding(30)
            .frame(maxWidth: 450)
        }
        .frame(minWidth: 500, minHeight: 400)
    }

    // 作業時間を更新
    private func updateWorkDuration() {
        if let value = Int(workText), value >= 1, value <= 120 {
            pomodoroManager.workDurationMinutes = value
        } else {
            // 無効な値の場合は元に戻す
            workText = "\(pomodoroManager.workDurationMinutes)"
        }
    }

    // 休憩時間を更新
    private func updateRestDuration() {
        if let value = Int(restText), value >= 1, value <= 60 {
            pomodoroManager.restDurationMinutes = value
        } else {
            // 無効な値の場合は元に戻す
            restText = "\(pomodoroManager.restDurationMinutes)"
        }
    }
}

#Preview {
    GeneralSettingsTab()
}
