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

    // サウンド設定（作業完了時）
    @Published var workCompletionSoundName: String {
        didSet {
            UserDefaults.standard.set(workCompletionSoundName, forKey: UserDefaultsKeys.workCompletionSoundName)
        }
    }

    // サウンド設定（休憩完了時）
    @Published var restCompletionSoundName: String {
        didSet {
            UserDefaults.standard.set(restCompletionSoundName, forKey: UserDefaultsKeys.restCompletionSoundName)
        }
    }

    // 音量設定（0.0 ~ 1.0）
    @Published var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.soundVolume)
        }
    }

    private init() {
        // UserDefaultsから設定を読み込み
        let savedWorkSound = UserDefaults.standard.string(forKey: UserDefaultsKeys.workCompletionSoundName)
        self.workCompletionSoundName = savedWorkSound ?? "Glass"

        let savedRestSound = UserDefaults.standard.string(forKey: UserDefaultsKeys.restCompletionSoundName)
        self.restCompletionSoundName = savedRestSound ?? "Ping"

        let savedVolume = UserDefaults.standard.float(forKey: UserDefaultsKeys.soundVolume)
        self.volume = savedVolume > 0 ? savedVolume : 0.5 // デフォルトは50%
    }

    // 作業完了時のサウンドを再生
    func playWorkCompletionSound() {
        playSound(named: workCompletionSoundName)
    }

    // 休憩完了時のサウンドを再生
    func playRestCompletionSound() {
        playSound(named: restCompletionSoundName)
    }

    // サウンドを再生（内部メソッド）
    private func playSound(named name: String) {
        // 「なし」が選択されている場合は再生しない
        guard name != "なし" else { return }

        // システムサウンドを再生
        if let sound = NSSound(named: name) {
            sound.volume = volume
            sound.play()
        }
    }

    // プレビュー用のサウンド再生
    func playPreviewSound(named name: String) {
        // 「なし」が選択されている場合は再生しない
        guard name != "なし" else { return }

        if let sound = NSSound(named: name) {
            sound.volume = volume
            sound.play()
        }
    }
}
