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
                    Text("セッション完了時に再生するサウンドを選択してください")
                        .font(.body)
                        .foregroundColor(.secondary)

                    // サウンド選択
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("完了サウンド")
                            .font(.headline)
                        Spacer()
                        Picker("", selection: $soundManager.soundName) {
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

                    // プレビュー再生ボタン
                    if soundManager.soundName != "なし" {
                        Button(action: {
                            soundManager.playPreviewSound(named: soundManager.soundName)
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("サウンドをプレビュー")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // 説明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ℹ️ サウンドについて")
                            .font(.headline)
                        Text("• 作業時間と休憩時間が完了したときに再生されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• 「なし」を選択するとサウンドは再生されません")
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
