//
//  UserDefaultsKeys.swift
//  Flyt
//
//  UserDefaultsのキー定義
//

import Foundation

/// UserDefaultsのキーを一元管理する構造体
struct UserDefaultsKeys {
    // ポモドーロ設定
    static let workDurationMinutes = "workDurationMinutes"
    static let restDurationMinutes = "restDurationMinutes"
    static let sessionCount = "sessionCount"
    static let lastResetDate = "lastResetDate"

    // 同期関連
    static let lastUpdated = "lastUpdated"

    // デバイス情報
    static let deviceId = "deviceId"

    // 認証フラグ（ユーザーが明示的にログインしたかどうか）
    static let hasUserLoggedIn = "hasUserLoggedIn"

    // サウンド設定
    static let workCompletionSoundName = "workCompletionSoundName"
    static let restCompletionSoundName = "restCompletionSoundName"
    static let soundVolume = "soundVolume"

    // UI設定
    static let windowBlurStrength = "windowBlurStrength"
    static let windowOpacity = "windowOpacity"

    // プライベートイニシャライザで初期化を防ぐ
    private init() {}
}
