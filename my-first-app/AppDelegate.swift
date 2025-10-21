//
//  AppDelegate.swift
//  my-first-app
//
//  グローバルキーボードショートカットを管理するクラス
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // グローバルホットキーの監視用
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("📱 アプリケーション起動完了")

        // グローバルホットキー(Control+I)を監視
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("⌨️ キー入力: keyCode=\(event.keyCode), modifiers=\(event.modifierFlags)")

            // Control+Iが押された場合
            if event.modifierFlags.contains(.control) && event.keyCode == 34 { // 34 = I
                print("✅ Control+I が検出されました")
                DispatchQueue.main.async {
                    self.toggleNoteWindow()
                }
                return nil // イベントを消費
            }
            return event
        }
        print("🎯 イベントモニター設定完了")
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
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
