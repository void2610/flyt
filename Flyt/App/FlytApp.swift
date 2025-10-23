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
