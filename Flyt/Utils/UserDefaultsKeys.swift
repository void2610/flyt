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

    // プライベートイニシャライザで初期化を防ぐ
    private init() {}
}
