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
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false

        // NSVisualEffectViewで半透明背景を作成
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true

        // SwiftUIビューをNSHostingViewでラップ（背景を透明に）
        let contentView = ContentView()
            .environment(\.modelContext, modelContext)
            .background(Color.clear)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // SwiftUIのツールバーを有効化
        hostingView.sceneBridgingOptions = [.toolbars]

        // HostingViewの背景も透明に
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        // VisualEffectViewの上にHostingViewを配置
        visualEffectView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])

        window.contentView = visualEffectView

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
