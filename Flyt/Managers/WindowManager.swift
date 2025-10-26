//
//  WindowManager.swift
//  Flyt
//
//  フルスクリーンアプリの上に表示できるウィンドウを手動管理
//

import AppKit
import SwiftUI
import Combine

class WindowManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = WindowManager()

    // タイマーウィンドウ
    private var timerWindow: NSWindow?

    // 設定ウィンドウ
    private var settingsWindow: NSWindow?

    // NSVisualEffectViewへの参照（不透明度変更のため）
    private var visualEffectView: NSVisualEffectView?

    // ウィンドウの不透明度（0.0〜1.0、デフォルト0.8）
    @Published var windowOpacity: Double {
        didSet {
            UserDefaults.standard.set(windowOpacity, forKey: UserDefaultsKeys.windowOpacity)
            updateWindowOpacity()
        }
    }

    private init() {
        // UserDefaultsから不透明度を読み込み
        let savedOpacity = UserDefaults.standard.double(forKey: UserDefaultsKeys.windowOpacity)
        self.windowOpacity = savedOpacity > 0 ? savedOpacity : 0.8
    }

    // タイマーウィンドウを作成
    func createTimerWindow() {
        // ウィンドウのサイズと位置（円形デザインに合わせて正方形に近く）
        let windowRect = NSRect(x: 0, y: 0, width: 500, height: 500)

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

        // グラスモーフィズムのための設定
        window.isOpaque = false
        window.backgroundColor = .clear

        // タイトルバーの設定
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

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

        // NSVisualEffectViewでグラスモーフィズム背景を作成
        let vfxView = NSVisualEffectView(frame: windowRect)
        vfxView.material = .hudWindow
        vfxView.blendingMode = .behindWindow
        vfxView.state = .active
        vfxView.wantsLayer = true
        vfxView.layer?.cornerRadius = 12
        vfxView.alphaValue = CGFloat(windowOpacity)

        // visualEffectViewを保存（後で不透明度を変更するため）
        self.visualEffectView = vfxView

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]

        // visualEffectViewにhostingViewを追加
        vfxView.addSubview(hostingView)
        hostingView.frame = vfxView.bounds

        window.contentView = vfxView

        self.timerWindow = window
    }

    // ウィンドウの不透明度を更新
    private func updateWindowOpacity() {
        visualEffectView?.alphaValue = CGFloat(windowOpacity)
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
        // タイマーウィンドウを非表示にする
        if let timerWindow = timerWindow, timerWindow.isVisible {
            hideWindowWithAnimation(timerWindow)
        }

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
