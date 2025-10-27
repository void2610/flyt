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

    // タイマーウィンドウのCABackdropLayerへの参照
    private var timerBackdropLayer: CALayer?

    // タイマーウィンドウのぼかしフィルターへの参照
    private var timerBlurFilter: NSObject?

    // タイマーウィンドウの半透明オーバーレイへの参照
    private var timerOverlayView: NSView?

    // 設定ウィンドウのCABackdropLayerへの参照
    private var settingsBackdropLayer: CALayer?

    // 設定ウィンドウのぼかしフィルターへの参照
    private var settingsBlurFilter: NSObject?

    // 設定ウィンドウの半透明オーバーレイへの参照
    private var settingsOverlayView: NSView?

    // 背景のぼかし強度（0.0〜1.0、デフォルト0.5）
    @Published var windowBlurStrength: Double {
        didSet {
            UserDefaults.standard.set(windowBlurStrength, forKey: UserDefaultsKeys.windowBlurStrength)
            updateBlurRadius()
        }
    }

    // ウィンドウの不透明度（0.0〜1.0、デフォルト0.2）
    @Published var windowOpacity: Double {
        didSet {
            UserDefaults.standard.set(windowOpacity, forKey: UserDefaultsKeys.windowOpacity)
            updateOverlayOpacity()
        }
    }

    // オーバーレイの色（デフォルトは白）
    @Published var overlayColor: Color? {
        didSet {
            // ColorをNSColorに変換してRGB値を保存
            guard let color = overlayColor else { return }
            let nsColor = NSColor(color)
            if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
                UserDefaults.standard.set(rgbColor.redComponent, forKey: UserDefaultsKeys.windowOverlayColorRed)
                UserDefaults.standard.set(rgbColor.greenComponent, forKey: UserDefaultsKeys.windowOverlayColorGreen)
                UserDefaults.standard.set(rgbColor.blueComponent, forKey: UserDefaultsKeys.windowOverlayColorBlue)
            }
            updateOverlayOpacity()
        }
    }

    private init() {
        // UserDefaultsからぼかし強度を読み込み
        let savedStrength = UserDefaults.standard.double(forKey: UserDefaultsKeys.windowBlurStrength)
        self.windowBlurStrength = savedStrength > 0 ? savedStrength : 0.5

        // UserDefaultsから不透明度を読み込み
        let savedOpacity = UserDefaults.standard.double(forKey: UserDefaultsKeys.windowOpacity)
        self.windowOpacity = savedOpacity > 0 ? savedOpacity : 0.2

        // UserDefaultsからオーバーレイの色を読み込み（デフォルトは白: 1.0, 1.0, 1.0）
        let savedRed = UserDefaults.standard.object(forKey: UserDefaultsKeys.windowOverlayColorRed) as? Double ?? 1.0
        let savedGreen = UserDefaults.standard.object(forKey: UserDefaultsKeys.windowOverlayColorGreen) as? Double ?? 1.0
        let savedBlue = UserDefaults.standard.object(forKey: UserDefaultsKeys.windowOverlayColorBlue) as? Double ?? 1.0

        self.overlayColor = Color(red: savedRed, green: savedGreen, blue: savedBlue)
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

        // 必須プロパティを設定
        backdrop.setValue(true, forKey: "enabled")  // Backdropを有効化
        backdrop.setValue(true, forKey: "windowServerAware")  // WindowServerでのレンダリング
        backdrop.setValue("flyt.backdrop.group", forKey: "groupName")  // 一意のグループ名
        backdrop.setValue(0.25, forKey: "scale")  // サンプリングサイズ（0.25推奨）

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
        self.timerBackdropLayer = backdrop
        self.timerBlurFilter = blur

        // 半透明のオーバーレイを追加（不透明度と色を制御）
        let overlay = NSView(frame: windowRect)
        overlay.wantsLayer = true
        let nsOverlayColor = NSColor(overlayColor ?? .white).withAlphaComponent(windowOpacity)
        overlay.layer?.backgroundColor = nsOverlayColor.cgColor
        overlay.autoresizingMask = [.width, .height]

        containerView.addSubview(overlay)

        // オーバーレイの参照を保存
        self.timerOverlayView = overlay

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
        // タイマーウィンドウのぼかしを更新
        if let backdrop = timerBackdropLayer {
            // windowBlurStrength を ぼかし半径にマッピング
            // 0.0 (0%) -> 半径 0 (ぼかしなし、背景が完全に見える)
            // 1.0 (100%) -> 半径 30 (最大のぼかし)
            let blurRadius = windowBlurStrength * 30.0

            // 完全に新しいフィルターオブジェクトを作成
            let filterClass = NSClassFromString("CAFilter") as! NSObject.Type
            let newBlur = filterClass.perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur").takeUnretainedValue() as! NSObject

            // 新しいフィルターにぼかし半径を設定
            newBlur.setValue(NSNumber(value: blurRadius), forKey: "inputRadius")
            newBlur.setValue(true, forKey: "inputNormalizeEdges")

            // 新しいフィルター配列を作成して適用
            backdrop.setValue([newBlur], forKey: "filters")

            // 参照を更新
            self.timerBlurFilter = newBlur
        }

        // 設定ウィンドウのぼかしを更新
        if let backdrop = settingsBackdropLayer {
            let blurRadius = windowBlurStrength * 30.0

            let filterClass = NSClassFromString("CAFilter") as! NSObject.Type
            let newBlur = filterClass.perform(NSSelectorFromString("filterWithType:"), with: "gaussianBlur").takeUnretainedValue() as! NSObject

            newBlur.setValue(NSNumber(value: blurRadius), forKey: "inputRadius")
            newBlur.setValue(true, forKey: "inputNormalizeEdges")

            backdrop.setValue([newBlur], forKey: "filters")

            self.settingsBlurFilter = newBlur
        }
    }

    // オーバーレイの不透明度と色を更新
    private func updateOverlayOpacity() {
        // タイマーウィンドウのオーバーレイを更新
        if let overlay = timerOverlayView {
            let nsOverlayColor = NSColor(overlayColor ?? .white).withAlphaComponent(windowOpacity)
            overlay.layer?.backgroundColor = nsOverlayColor.cgColor
        }

        // 設定ウィンドウのオーバーレイを更新
        if let overlay = settingsOverlayView {
            let nsOverlayColor = NSColor(overlayColor ?? .white).withAlphaComponent(windowOpacity)
            overlay.layer?.backgroundColor = nsOverlayColor.cgColor
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
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // ウィンドウの基本設定
        window.title = "Flyt 設定"
        window.center()
        window.isReleasedWhenClosed = false

        // グラスモーフィズムのための設定
        window.isOpaque = false
        window.backgroundColor = .clear

        // タイトルバーの設定
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden

        // 通常のウィンドウレベル（設定ウィンドウはフルスクリーン上に表示する必要はない）
        window.level = .normal

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

        // 必須プロパティを設定
        backdrop.setValue(true, forKey: "enabled")  // Backdropを有効化
        backdrop.setValue(true, forKey: "windowServerAware")  // WindowServerでのレンダリング
        backdrop.setValue("flyt.settings.backdrop.group", forKey: "groupName")  // 一意のグループ名
        backdrop.setValue(0.25, forKey: "scale")  // サンプリングサイズ（0.25推奨）

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
        self.settingsBackdropLayer = backdrop
        self.settingsBlurFilter = blur

        // 半透明のオーバーレイを追加（不透明度と色を制御）
        let overlay = NSView(frame: windowRect)
        overlay.wantsLayer = true
        let nsOverlayColor = NSColor(overlayColor ?? .white).withAlphaComponent(windowOpacity)
        overlay.layer?.backgroundColor = nsOverlayColor.cgColor
        overlay.autoresizingMask = [.width, .height]

        containerView.addSubview(overlay)

        // オーバーレイの参照を保存
        self.settingsOverlayView = overlay

        // SwiftUIビューをNSHostingViewでラップ
        let contentView = SettingsView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.autoresizingMask = [.width, .height]

        // containerViewにhostingViewを追加
        containerView.addSubview(hostingView)
        hostingView.frame = containerView.bounds

        window.contentView = containerView

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
