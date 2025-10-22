//
//  AppDelegate.swift
//  Flyt
//
//  グローバルキーボードショートカットを管理するクラス
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    // 権限チェック用タイマー
    private var permissionCheckTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // アクセサリアプリケーションとして動作（Dockアイコンを非表示）
        NSApp.setActivationPolicy(.accessory)
        // メニューバーアイコンをセットアップ
        MenuBarManager.shared.setupMenuBar()
        // イベントモニターを設定
        setupEventMonitors()
        // ホットコーナーマネージャーをセットアップ
        setupHotCorner()

        // 権限がない場合、定期的にチェックして自動的にイベントモニターを再登録
        if !AXIsProcessTrusted() {
            checkAccessibilityPermission()

            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                if AXIsProcessTrusted() {
                    self?.setupEventMonitors()
                    self?.stopPermissionMonitoring()
                }
            }
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

    // 設定されたホットキーと一致した場合にタイマーウィンドウをトグル
    private func handleKeyEvent(_ event: NSEvent, isLocal: Bool) -> NSEvent? {
        if HotKeyManager.shared.matches(event: event) {
            DispatchQueue.main.async {
                self.toggleNoteWindow()
            }
            return nil // イベントを消費
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
            // アラートを表示
            showAccessibilityPermissionAlert()
        }

        return accessEnabled
    }

    // アクセシビリティ権限要求アラート
    private func showAccessibilityPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要です"
            alert.informativeText = "本アプリの機能を使用するには、アクセシビリティ権限が必要です。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "システム設定を開く")
            alert.addButton(withTitle: "後で")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // アクセシビリティ設定を直接開く
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }

    // ホットエッジをセットアップ
    private func setupHotCorner() {
        // ホットエッジのトリガーコールバックを設定
        HotCornerManager.shared.onTrigger = { [weak self] in
            DispatchQueue.main.async {
                self?.toggleNoteWindow()
            }
        }

        // 監視を開始
        HotCornerManager.shared.startMonitoring()
    }

    // タイマーウィンドウを開く/閉じる
    private func toggleNoteWindow() {
        WindowManager.shared.toggleWindow()
    }

    // WindowManagerでウィンドウを初期化
    func initializeWindow() {
        WindowManager.shared.createNoteWindow()
    }

    // 権限の監視を停止
    private func stopPermissionMonitoring() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }

    func applicationWillTerminate(_ notification: Notification) {
        // イベントモニターをクリーンアップ
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // ホットエッジ監視を停止
        HotCornerManager.shared.stopMonitoring()

        // タイマーをクリーンアップ
        stopPermissionMonitoring()
    }
}
