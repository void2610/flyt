//
//  AppDelegate.swift
//  my-first-app
//
//  グローバルキーボードショートカットを管理するクラス
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // イベントモニター（ローカルとグローバル）
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("📱 アプリケーション起動完了")

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

        print("🎯 イベントモニター設定完了（ローカル + グローバル）")
    }

    // キーイベント処理
    private func handleKeyEvent(_ event: NSEvent, isLocal: Bool) -> NSEvent? {
        let source = isLocal ? "ローカル" : "グローバル"
        print("⌨️ [\(source)] キー入力: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")

        // Control+Iが押された場合
        if event.modifierFlags.contains(.control) && event.keyCode == 34 { // 34 = I
            print("✅ Control+I が検出されました")
            DispatchQueue.main.async {
                self.toggleNoteWindow()
            }
            return isLocal ? nil : event // ローカルの場合はイベントを消費
        }
        return event
    }

    // アクセシビリティ権限をチェック
    private func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if accessEnabled {
            print("✅ アクセシビリティ権限が許可されています")
        } else {
            print("⚠️ アクセシビリティ権限が必要です")
            // 権限要求ダイアログを表示
            DispatchQueue.main.async {
                self.showAccessibilityAlert()
            }
        }
    }

    // アクセシビリティ権限要求アラート
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要です"
        alert.informativeText = "フルスクリーンアプリ上でもキーボードショートカット（Control+I）を使用するには、アクセシビリティ権限が必要です。\n\n「システム設定」を開いて、「プライバシーとセキュリティ」→「アクセシビリティ」でこのアプリを許可してください。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "システム設定を開く")
        alert.addButton(withTitle: "後で")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // システム設定を開く
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
    
    // メモウィンドウを開く/閉じる
    private func toggleNoteWindow() {
        print("🔄 toggleNoteWindow() 実行")
        print("📊 現在のウィンドウ数: \(NSApplication.shared.windows.count)")

        // 全ウィンドウを列挙
        for (index, window) in NSApplication.shared.windows.enumerated() {
            print("   ウィンドウ[\(index)]: identifier=\(window.identifier?.rawValue ?? "nil"), title=\(window.title), visible=\(window.isVisible)")
        }

        // "note-window"というIDのウィンドウを探す
        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "note-window" }) {
            print("✅ メモウィンドウが見つかりました")
            if window.isVisible {
                print("👁️ ウィンドウを非表示にします")
                window.orderOut(nil)
            } else {
                print("👁️ ウィンドウを表示します")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            print("⚠️ メモウィンドウが見つかりません。通知を送信します")
            // NotificationCenterで通知を送る
            NotificationCenter.default.post(name: NSNotification.Name("ToggleNoteWindow"), object: nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // イベントモニターをクリーンアップ
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        print("🧹 イベントモニターをクリーンアップしました")
    }
}
