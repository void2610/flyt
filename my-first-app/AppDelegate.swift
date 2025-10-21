//
//  AppDelegate.swift
//  my-first-app
//
//  グローバルキーボードショートカットを管理するクラス
//

import AppKit
import SwiftUI
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    // イベントモニター（ローカルとグローバル）
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    // ModelContext（ウィンドウ作成用）
    var modelContext: ModelContext?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // アクセサリアプリケーションとして動作（Dockアイコンを非表示）
        NSApp.setActivationPolicy(.accessory)

        // アクセシビリティ権限をチェック
        checkAccessibilityPermission()

        // ローカルイベントモニター（このアプリ内でイベントを消費）
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event, isLocal: true)
        }

        // グローバルイベントモニター（他のアプリでも検出）
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = self.handleKeyEvent(event, isLocal: false)
        }
    }

    // キーイベント処理
    private func handleKeyEvent(_ event: NSEvent, isLocal: Bool) -> NSEvent? {
        // Control+Iが押された場合
        if event.modifierFlags.contains(.control) && event.keyCode == 34 { // 34 = I
            DispatchQueue.main.async {
                self.toggleNoteWindow()
            }
            return isLocal ? nil : event // ローカルの場合はイベントを消費
        }
        return event
    }

    // アクセシビリティ権限をチェック
    @discardableResult
    private func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            // 3秒後にシステム設定を開く
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.openAccessibilitySettings()
            }
        }

        return accessEnabled
    }

    // アクセシビリティ設定を直接開く
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // メモウィンドウを開く/閉じる
    private func toggleNoteWindow() {
        WindowManager.shared.toggleWindow()
    }

    // WindowManagerでウィンドウを初期化
    func initializeWindow(modelContext: ModelContext) {
        self.modelContext = modelContext
        WindowManager.shared.createNoteWindow(modelContext: modelContext)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // イベントモニターをクリーンアップ
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
