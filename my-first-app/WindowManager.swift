//
//  WindowManager.swift
//  my-first-app
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

    private init() {}

    // メモウィンドウを作成
    func createNoteWindow(modelContext: ModelContext) {
        // ウィンドウのサイズと位置
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600)

        // NSWindowを手動で作成
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        // ウィンドウの基本設定
        window.title = "Quick Note"
        window.center()
        window.isReleasedWhenClosed = false

        // フルスクリーンアプリの上に表示するための設定
        window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

        // 追加設定
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()
            .environment(\.modelContext, modelContext)

        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        self.noteWindow = window
    }

    // ウィンドウの表示/非表示を切り替え
    func toggleWindow() {
        guard let window = noteWindow else { return }

        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // ウィンドウを閉じる
    func closeWindow() {
        noteWindow?.close()
        noteWindow = nil
    }
}
