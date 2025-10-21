//
//  HotKeyManager.swift
//  Flyt
//
//  ホットキーの設定を管理するクラス
//

import AppKit
import SwiftUI

class HotKeyManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = HotKeyManager()

    // ホットキーの設定
    @Published var modifierFlags: NSEvent.ModifierFlags = [.control]
    @Published var keyCode: UInt16 = 34 // デフォルトは「I」

    // UserDefaultsのキー
    private let modifierFlagsKey = "HotKeyModifierFlags"
    private let keyCodeKey = "HotKeyKeyCode"

    private init() {
        loadSettings()
    }

    // 設定を保存
    func saveSettings() {
        UserDefaults.standard.set(modifierFlags.rawValue, forKey: modifierFlagsKey)
        UserDefaults.standard.set(Int(keyCode), forKey: keyCodeKey)
    }

    // 設定を読み込み
    func loadSettings() {
        if let savedModifierFlags = UserDefaults.standard.object(forKey: modifierFlagsKey) as? UInt {
            modifierFlags = NSEvent.ModifierFlags(rawValue: savedModifierFlags)
        }
        if let savedKeyCode = UserDefaults.standard.object(forKey: keyCodeKey) as? Int {
            keyCode = UInt16(savedKeyCode)
        }
    }

    // ホットキーを設定
    func setHotKey(modifierFlags: NSEvent.ModifierFlags, keyCode: UInt16) {
        self.modifierFlags = modifierFlags
        self.keyCode = keyCode
        saveSettings()
    }

    // ホットキーの文字列表現を取得
    func getHotKeyString() -> String {
        var parts: [String] = []

        // モディファイアキーを追加
        if modifierFlags.contains(.control) {
            parts.append("⌃")
        }
        if modifierFlags.contains(.option) {
            parts.append("⌥")
        }
        if modifierFlags.contains(.shift) {
            parts.append("⇧")
        }
        if modifierFlags.contains(.command) {
            parts.append("⌘")
        }

        // キーコードから文字を取得
        if let key = keyCodeToString(keyCode) {
            parts.append(key)
        }

        return parts.joined()
    }

    // キーコードを文字列に変換
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        // よく使われるキーコードのマッピング
        let keyCodeMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
            45: "N", 46: "M", 47: ".", 49: "Space", 50: "`",
            36: "Return", 48: "Tab", 51: "Delete", 53: "Escape",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        return keyCodeMap[keyCode]
    }

    // イベントがホットキーに一致するかチェック
    func matches(event: NSEvent) -> Bool {
        return event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifierFlags && event.keyCode == keyCode
    }
}
