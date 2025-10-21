//
//  HotCornerManager.swift
//  Flyt
//
//  ホットエッジ（画面の辺）の設定を管理するクラス
//

import AppKit
import SwiftUI

// ホットエッジの位置
enum HotCorner: String, CaseIterable, Codable {
    case top = "上"
    case bottom = "下"
    case left = "左"
    case right = "右"
    case disabled = "無効"
}

class HotCornerManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = HotCornerManager()

    // ホットエッジの設定
    @Published var selectedCorner: HotCorner = .disabled
    @Published var isEnabled: Bool = false

    // UserDefaultsのキー
    private let selectedCornerKey = "HotCornerSelectedCorner"
    private let isEnabledKey = "HotCornerIsEnabled"

    // マウスイベントモニター（グローバルとローカル）
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    // タイマー（遅延トリガー用）
    private var triggerTimer: Timer?

    // 最後にトリガーされた時刻（クールダウン用）
    private var lastTriggered: Date?

    // ホットエッジの判定幅（ピクセル）
    private let edgeThreshold: CGFloat = 3

    // トリガーまでの遅延時間（秒）
    private let triggerDelay: TimeInterval = 0.3

    // クールダウン時間（秒）
    private let cooldownDuration: TimeInterval = 2.0

    // トリガーコールバック
    var onTrigger: (() -> Void)?

    private init() {
        loadSettings()
    }

    // 設定を保存
    func saveSettings() {
        UserDefaults.standard.set(selectedCorner.rawValue, forKey: selectedCornerKey)
        UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
    }

    // 設定を読み込み
    func loadSettings() {
        if let savedCorner = UserDefaults.standard.string(forKey: selectedCornerKey),
           let corner = HotCorner(rawValue: savedCorner) {
            selectedCorner = corner
        }
        isEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)
    }

    // マウス監視を開始
    func startMonitoring() {
        guard isEnabled && selectedCorner != .disabled else {
            stopMonitoring()
            return
        }

        // 既存のモニターをクリーンアップ
        stopMonitoring()

        // グローバルマウスムーブイベントを監視（他のアプリでも検出）
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
        }

        // ローカルマウスムーブイベントを監視（このアプリ内でも検出）
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMove(event)
            return event
        }
    }

    // マウス監視を停止
    func stopMonitoring() {
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }

        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMonitor = nil
        }

        // タイマーをキャンセル
        triggerTimer?.invalidate()
        triggerTimer = nil
    }

    // マウス移動イベントを処理
    private func handleMouseMove(_ event: NSEvent) {
        guard let screen = NSScreen.main else { return }

        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame

        // マウスがホットコーナーにあるかチェック
        if isInHotCorner(mouseLocation: mouseLocation, screenFrame: screenFrame) {
            // タイマーがまだ開始されていない場合のみ開始
            if triggerTimer == nil {
                triggerTimer = Timer.scheduledTimer(withTimeInterval: triggerDelay, repeats: false) { [weak self] _ in
                    self?.triggerHotCorner()
                }
            }
        } else {
            // ホットコーナーから出たらタイマーをキャンセル
            triggerTimer?.invalidate()
            triggerTimer = nil
        }
    }

    // マウスがホットエッジにあるかチェック
    private func isInHotCorner(mouseLocation: CGPoint, screenFrame: CGRect) -> Bool {
        switch selectedCorner {
        case .top:
            return mouseLocation.y >= screenFrame.maxY - edgeThreshold
        case .bottom:
            return mouseLocation.y <= screenFrame.minY + edgeThreshold
        case .left:
            return mouseLocation.x <= screenFrame.minX + edgeThreshold
        case .right:
            return mouseLocation.x >= screenFrame.maxX - edgeThreshold
        case .disabled:
            return false
        }
    }

    // ホットコーナーをトリガー
    private func triggerHotCorner() {
        // クールダウン中かチェック
        if let lastTriggered = lastTriggered,
           Date().timeIntervalSince(lastTriggered) < cooldownDuration {
            return
        }

        // トリガー実行
        lastTriggered = Date()
        onTrigger?()

        // タイマーをリセット
        triggerTimer = nil
    }

    // 設定を変更
    func updateSettings(corner: HotCorner, enabled: Bool) {
        selectedCorner = corner
        isEnabled = enabled
        saveSettings()

        // 監視を再開
        if enabled && corner != .disabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
}
