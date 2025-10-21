//
//  WindowManager.swift
//  Flyt
//
//  フルスクリーンアプリの上に表示できるウィンドウを手動管理
//

import AppKit
import SwiftUI
import SwiftData

class WindowManager {
    // シングルトンインスタンス
    static let shared = WindowManager()

    // メモウィンドウ
    private var noteWindow: NSWindow?

    // 設定ウィンドウ
    private var settingsWindow: NSWindow?

    private init() {}

    // メモウィンドウを作成
    func createNoteWindow(modelContext: ModelContext) {
        // ウィンドウのサイズと位置
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600)

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
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

        // 追加設定
        window.hidesOnDeactivate = false

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()
            .environment(\.modelContext, modelContext)

        let hostingView = NSHostingView(rootView: contentView)

        // SwiftUIのツールバーを有効化
        hostingView.sceneBridgingOptions = [.toolbars]

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

    // アニメーション付きでウィンドウを表示
    private func showWindowWithAnimation(_ window: NSWindow) {
        window.center()
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        })
    }

    // アニメーション付きでウィンドウを非表示
    private func hideWindowWithAnimation(_ window: NSWindow) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
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
        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 300)

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
