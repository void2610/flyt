//
//  SoundSettingsTab.swift
//  Flyt
//
//  サウンド設定タブ
//

import SwiftUI

struct SoundSettingsTab: View {
    @ObservedObject var soundManager = SoundManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("サウンド設定")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 16) {
                    // 音量設定
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("音量")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(soundManager.volume * 100))%")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $soundManager.volume, in: 0...1, step: 0.1)
                            .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )

                    Divider()
                        .padding(.vertical, 8)

                    Text("セッション完了時に再生するサウンドを選択してください")
                        .font(.body)
                        .foregroundColor(.secondary)

                    // 作業完了サウンド選択
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text("作業完了サウンド")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: $soundManager.workCompletionSoundName) {
                            ForEach(SoundManager.availableSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )

                    // 作業完了サウンドのプレビュー再生ボタン
                    if soundManager.workCompletionSoundName != "なし" {
                        Button(action: {
                            soundManager.playPreviewSound(named: soundManager.workCompletionSoundName)
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("作業完了サウンドをプレビュー")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }

                    // 休憩完了サウンド選択
                    HStack {
                        Image(systemName: "cup.and.saucer")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("休憩完了サウンド")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: $soundManager.restCompletionSoundName) {
                            ForEach(SoundManager.availableSounds, id: \.self) { sound in
                                Text(sound).tag(sound)
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    )

                    // 休憩完了サウンドのプレビュー再生ボタン
                    if soundManager.restCompletionSoundName != "なし" {
                        Button(action: {
                            soundManager.playPreviewSound(named: soundManager.restCompletionSoundName)
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("休憩完了サウンドをプレビュー")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // 説明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ℹ️ サウンドについて")
                            .font(.headline)
                        Text("• 作業時間と休憩時間が完了したときに、それぞれ異なるサウンドが再生されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 「なし」を選択するとサウンドは再生されません")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 音量はすべてのサウンドに共通で適用されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.2))
                    )
                }
            }
            .padding(30)
            .frame(maxWidth: 450)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    SoundSettingsTab()
}
