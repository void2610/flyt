//
//  SoundManager.swift
//  Flyt
//
//  サウンド再生を管理するクラス
//

import AppKit
import Combine

class SoundManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = SoundManager()

    // 利用可能なシステムサウンド
    static let availableSounds: [String] = [
        "なし",
        "Basso",
        "Blow",
        "Bottle",
        "Frog",
        "Funk",
        "Glass",
        "Hero",
        "Morse",
        "Ping",
        "Pop",
        "Purr",
        "Sosumi",
        "Submarine",
        "Tink"
    ]

    // サウンド設定
    @Published var soundName: String {
        didSet {
            UserDefaults.standard.set(soundName, forKey: UserDefaultsKeys.soundName)
        }
    }

    private init() {
        // UserDefaultsから設定を読み込み
        let savedSound = UserDefaults.standard.string(forKey: UserDefaultsKeys.soundName)
        self.soundName = savedSound ?? "Glass"
    }

    // セッション完了時のサウンドを再生
    func playCompletionSound() {
        // 「なし」が選択されている場合は再生しない
        guard soundName != "なし" else { return }

        // システムサウンドを再生
        if let sound = NSSound(named: soundName) {
            sound.play()
        }
    }

    // プレビュー用のサウンド再生
    func playPreviewSound(named name: String) {
        // 「なし」が選択されている場合は再生しない
        guard name != "なし" else { return }

        if let sound = NSSound(named: name) {
            sound.play()
        }
    }
}
