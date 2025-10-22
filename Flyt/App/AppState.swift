//
//  AppState.swift
//  Flyt
//
//  アプリケーション全体の状態を管理するクラス
//

import SwiftUI

// アプリケーション全体の状態を管理
class AppState: ObservableObject {
    // タイマーウィンドウの表示状態
    @Published var isTimerWindowVisible = false

    // シングルトンインスタンス
    static let shared = AppState()

    private init() {}

    // ウィンドウの表示/非表示を切り替え
    func toggleTimerWindow() {
        isTimerWindowVisible.toggle()
    }
}
