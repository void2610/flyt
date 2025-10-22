//
//  WindowManager.swift
//  Flyt
//
//  フルスクリーンアプリの上に表示できるウィンドウを手動管理
//

import AppKit
import SwiftUI

class WindowManager {
    // シングルトンインスタンス
    static let shared = WindowManager()

    // タイマーウィンドウ
    private var timerWindow: NSWindow?

    // 設定ウィンドウ
    private var settingsWindow: NSWindow?

    private init() {}

    // タイマーウィンドウを作成
    func createTimerWindow() {
        // ウィンドウのサイズと位置
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 350)

        // NSPanelを使用（フルスクリーンアプリの上に安定して表示するため）
        let window = NSPanel(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // ウィンドウの基本設定
        window.title = "Flyt"
        window.center()
        window.isReleasedWhenClosed = false

        // タイトルバーの設定
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible

        // フルスクリーンアプリの上に表示するための設定
        // NSPanel + .nonactivatingPanel + .floating でフルスクリーン上に安定表示
        window.level = .floating
        window.collectionBehavior = [
            .canJoinAllSpaces,          // 全てのスペースで表示可能
            .fullScreenAuxiliary,       // フルスクリーンアプリと一緒に表示
            .transient,                 // 一時的なウィンドウとして扱う
            .ignoresCycle               // Cmd+Tabのサイクルから除外
        ]

        // 追加設定
        window.hidesOnDeactivate = false

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()

        let hostingView = NSHostingView(rootView: contentView)

        window.contentView = hostingView

        self.timerWindow = window
    }

    // ウィンドウの表示/非表示を切り替え
    func toggleWindow() {
        guard let window = timerWindow else { return }

        if window.isVisible {
            hideWindowWithAnimation(window)
        } else {
            showWindowWithAnimation(window)
        }
    }

    // ウィンドウを表示（toggleではなく必ず表示）
    func showWindow() {
        guard let window = timerWindow else { return }

        if !window.isVisible {
            showWindowWithAnimation(window)
        } else {
            // 既に表示されている場合は最前面に
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // アニメーション付きでウィンドウを表示
    private func showWindowWithAnimation(_ window: NSWindow) {
        // collectionBehaviorを先に設定
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]

        // ウィンドウレベルを明示的に設定（フルスクリーンアプリの上に表示するため）
        // NSPanel + .floating で安定した動作を保証
        window.level = .floating

        // 現在アクティブなスペース（フルスクリーンアプリが表示されているスペース）を取得
        if let screen = NSScreen.main {
            // スクリーンの中央にウィンドウを配置
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.alphaValue = 0.0

        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 1.0
        })
    }

    // アニメーション付きでウィンドウを非表示
    private func hideWindowWithAnimation(_ window: NSWindow) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1.0
        })
    }

    // ウィンドウを閉じる
    func closeWindow() {
        timerWindow?.close()
        timerWindow = nil
    }

    // 設定ウィンドウを作成
    func createSettingsWindow() {
        // 既に設定ウィンドウが存在する場合は作成しない
        if settingsWindow != nil {
            return
        }

        // ウィンドウのサイズと位置
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 450)

        // NSWindowを手動で作成
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        // ウィンドウの基本設定
        window.title = "Flyt 設定"
        window.center()
        window.isReleasedWhenClosed = false

        // 通常のウィンドウレベル（設定ウィンドウはフルスクリーン上に表示する必要はない）
        window.level = .normal

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = SettingsView()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        self.settingsWindow = window
    }

    // 設定ウィンドウを表示
    func showSettingsWindow() {
        // 設定ウィンドウがまだ作成されていない場合は作成
        if settingsWindow == nil {
            createSettingsWindow()
        }

        guard let window = settingsWindow else { return }

        // ウィンドウを前面に表示
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // 設定ウィンドウを閉じる
    func closeSettingsWindow() {
        settingsWindow?.close()
        settingsWindow = nil
    }
}
