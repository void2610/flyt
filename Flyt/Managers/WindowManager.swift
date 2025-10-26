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

    // CABackdropLayerへの参照
    private var backdropLayer: CALayer?

    // ぼかしフィルターへの参照
    private var blurFilter: NSObject?

    // 背景のぼかし強度（0.0〜1.0、デフォルト0.5）
    @Published var windowBlurStrength: Double {
        didSet {
            UserDefaults.standard.set(windowBlurStrength, forKey: UserDefaultsKeys.windowBlurStrength)
            updateBlurRadius()
        }
    }

    private init() {
        // UserDefaultsからぼかし強度を読み込み
        let savedStrength = UserDefaults.standard.double(forKey: UserDefaultsKeys.windowBlurStrength)
        self.windowBlurStrength = savedStrength > 0 ? savedStrength : 0.5
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

        // 自前でCABackdropLayerを作成してグラスモーフィズム背景を実現
        let containerView = NSView(frame: windowRect)
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.masksToBounds = true

        // Core Imageフィルターを無効化（WindowServerでのレンダリングと競合しないように）
        containerView.setValue(false, forKey: "layerUsesCoreImageFilters")

        // CABackdropLayerを作成（プライベートクラス）
        let backdropLayerClass = NSClassFromString("CABackdropLayer") as! CALayer.Type
        let backdrop = backdropLayerClass.init()
        backdrop.frame = windowRect

        // WindowServerでのレンダリングを有効化
        backdrop.setValue(true, forKey: "windowServerAware")

        // 一意のグループ名を設定
        backdrop.setValue("flyt.backdrop.group", forKey: "groupName")

        // サンプリングサイズを設定（1.0が適切、2.0だと遅くなる）
        backdrop.setValue(1.0, forKey: "scale")

        // ぼかしフィルターを作成
        let filterClass = NSClassFromString("CAFilter") as! NSObject.Type
        let blur = filterClass.perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur").takeUnretainedValue() as! NSObject

        // 初期ぼかし半径を設定
        let initialRadius = windowBlurStrength * 30.0
        blur.setValue(NSNumber(value: initialRadius), forKey: "inputRadius")
        blur.setValue(true, forKey: "inputNormalizeEdges")

        // フィルターを適用
        backdrop.setValue([blur], forKey: "filters")

        // レイヤーを追加
        containerView.layer?.insertSublayer(backdrop, at: 0)

        // 参照を保存
        self.backdropLayer = backdrop
        self.blurFilter = blur

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]

        // containerViewにhostingViewを追加
        containerView.addSubview(hostingView)
        hostingView.frame = containerView.bounds

        window.contentView = containerView

        self.timerWindow = window
    }

    // ぼかし半径を更新
    private func updateBlurRadius() {
        guard let blur = blurFilter else {
            print("⚠️ blurFilter is nil")
            return
        }

        // windowBlurStrength を ぼかし半径にマッピング
        // 0.0 (0%) -> 半径 0 (ぼかしなし、背景が完全に見える)
        // 1.0 (100%) -> 半径 30 (最大のぼかし)
        let blurRadius = windowBlurStrength * 30.0

        print("🔍 Updating blur radius to: \(blurRadius) (strength: \(windowBlurStrength))")

        // inputRadiusを直接設定
        blur.setValue(NSNumber(value: blurRadius), forKey: "inputRadius")

        // 設定後の値を確認
        if let currentRadius = blur.value(forKey: "inputRadius") {
            print("✅ Blur radius set to: \(currentRadius)")
        }
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
