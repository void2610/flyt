//
//  FlytApp.swift
//  Flyt
//
//  Created by Izumi Shuya on 2025/10/21.
//

import SwiftUI

@main
struct FlytApp: App {
    // AppDelegateを設定
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Supabaseクライアントの初期化（最初にアクセスすることで初期化）
        _ = SupabaseClientWrapper.shared

        // AuthManagerの初期化と認証状態の確認
        _ = AuthManager.shared

        // SyncManagerの初期化
        _ = SyncManager.shared
    }

    var body: some Scene {
        // 見えないダミーウィンドウ
        WindowGroup {
            InitializerView()
                .frame(width: 0, height: 0)
                .onAppear {
                    // ウィンドウを初期化
                    appDelegate.initializeWindow()

                    // ダミーウィンドウを非表示
                    if let window = NSApplication.shared.windows.first {
                        window.setIsVisible(false)
                    }

                    // 認証済みの場合は同期を開始
                    if AuthManager.shared.isAuthenticated {
                        SyncManager.shared.startSync()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
    }
}

// 初期化専用のダミービュー
struct InitializerView: View {
    var body: some View {
        EmptyView()
    }
}
