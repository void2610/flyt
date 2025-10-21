//
//  AppDelegate.swift
//  Flyt
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

    // 権限チェック用タイマー
    private var permissionCheckTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // アクセサリアプリケーションとして動作（Dockアイコンを非表示）
        NSApp.setActivationPolicy(.accessory)

        // メニューバーアイコンをセットアップ
        MenuBarManager.shared.setupMenuBar()

        // イベントモニターを設定
        setupEventMonitors()

        // 権限がない場合、定期的にチェックして自動的にイベントモニターを再登録
        if !AXIsProcessTrusted() {
            checkAccessibilityPermission()
            startPermissionMonitoring()
        }
    }

    // イベントモニターをセットアップ
    private func setupEventMonitors() {
        // 既存のモニターをクリーンアップ
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // ローカルイベントモニター（このアプリ内でイベントを消費）
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event, isLocal: true)
        }
        
        // グローバルイベントモニター（他のアプリでも検出）
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = self.handleKeyEvent(event, isLocal: false)
        }
    }

    // 権限の監視を開始
    private func startPermissionMonitoring() {
        // 1秒ごとに権限をチェック
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if AXIsProcessTrusted() {
                // 権限が付与されたらイベントモニターを再登録
                self?.setupEventMonitors()
                self?.stopPermissionMonitoring()
            }
        }
    }

    // 権限の監視を停止
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
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
        // システムダイアログを表示せずにチェック
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            // 初回のみアラートを表示
            showAccessibilityPermissionAlert()
        }

        return accessEnabled
    }

    // アクセシビリティ権限要求アラート
    private func showAccessibilityPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要です"
            alert.informativeText = """
            フルスクリーンアプリ上でもキーボードショートカット（Control+I）を使用するには、アクセシビリティ権限が必要です。

            システム設定でこのアプリを見つけてトグルをオンにしてください。
            権限を付与すると自動的に有効になります（再起動不要）。
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "システム設定を開く")
            alert.addButton(withTitle: "後で")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.openAccessibilitySettings()
            }
        }
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

        // タイマーをクリーンアップ
        stopPermissionMonitoring()
    }
}
