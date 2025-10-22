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
    private var noteWindow: NSWindow?

    // 設定ウィンドウ
    private var settingsWindow: NSWindow?

    private init() {}

    // タイマーウィンドウを作成
    func createNoteWindow() {
        // ウィンドウのサイズと位置
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 350)

        // NSWindowを手動で作成
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
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
        // CGShieldingWindowLevel() は最も高いウィンドウレベルの一つ
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        window.collectionBehavior = [
            .canJoinAllSpaces,          // 全てのスペースで表示可能
            .fullScreenAuxiliary,       // フルスクリーンアプリの補助ウィンドウとして動作
            .transient,                 // 一時的なウィンドウとして扱う
            .ignoresCycle               // Cmd+Tab でのウィンドウ切り替えに含めない
        ]

        // 追加設定
        window.hidesOnDeactivate = false

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()

        let hostingView = NSHostingView(rootView: contentView)

        window.contentView = hostingView

        self.noteWindow = window
    }

    // ウィンドウの表示/非表示を切り替え
    func toggleWindow() {
        guard let window = noteWindow else { return }

        if window.isVisible {
            hideWindowWithAnimation(window)
        } else {
            showWindowWithAnimation(window)
        }
    }

    // ウィンドウを表示（toggleではなく必ず表示）
    func showWindow() {
        guard let window = noteWindow else { return }

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

        // ウィンドウレベルを最高レベルに設定（フルスクリーンアプリの上に表示するため）
        let shieldingLevel = Int(CGShieldingWindowLevel())

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

        // orderFront よりも先にレベルを設定
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
        noteWindow?.close()
        noteWindow = nil
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
