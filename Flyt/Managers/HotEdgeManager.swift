//
//  HotEdgeManager.swift
//  Flyt
//
//  ホットエッジ（画面の辺）の設定を管理するクラス
//

import AppKit
import SwiftUI

// ホットエッジの位置
enum HotEdge: String, CaseIterable, Codable {
    case top = "上"
    case bottom = "下"
    case left = "左"
    case right = "右"
    case disabled = "無効"
}

class HotEdgeManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = HotEdgeManager()

    // ホットエッジの設定
    @Published var selectedEdge: HotEdge = .disabled
    @Published var isEnabled: Bool = false
    @Published var edgeThreshold: CGFloat = 3.0  // ホットエッジの判定幅（ピクセル）
    @Published var triggerDelay: TimeInterval = 0.3  // トリガーまでの遅延時間（秒）

    // UserDefaultsのキー
    private let selectedEdgeKey = "HotEdgeSelectedEdge"
    private let isEnabledKey = "HotEdgeIsEnabled"
    private let edgeThresholdKey = "HotEdgeEdgeThreshold"
    private let triggerDelayKey = "HotEdgeTriggerDelay"

    // マウスイベントモニター（グローバルとローカル）
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    // タイマー（遅延トリガー用）
    private var triggerTimer: Timer?

    // 最後にトリガーされた時刻（クールダウン用）
    private var lastTriggered: Date?

    // クールダウン時間（秒）
    private let cooldownDuration: TimeInterval = 0.5

    // トリガーコールバック
    var onTrigger: (() -> Void)?

    private init() {
        loadSettings()
    }

    // 設定を保存
    func saveSettings() {
        UserDefaults.standard.set(selectedEdge.rawValue, forKey: selectedEdgeKey)
        UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
        UserDefaults.standard.set(Double(edgeThreshold), forKey: edgeThresholdKey)
        UserDefaults.standard.set(triggerDelay, forKey: triggerDelayKey)
    }

    // 設定を読み込み
    func loadSettings() {
        if let savedEdge = UserDefaults.standard.string(forKey: selectedEdgeKey),
           let edge = HotEdge(rawValue: savedEdge) {
            selectedEdge = edge
        }
        isEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)

        // エッジ判定幅の読み込み（デフォルト: 3.0）
        let savedThreshold = UserDefaults.standard.double(forKey: edgeThresholdKey)
        if savedThreshold > 0 {
            edgeThreshold = CGFloat(savedThreshold)
        }

        // トリガー遅延時間の読み込み（デフォルト: 0.3）
        let savedDelay = UserDefaults.standard.double(forKey: triggerDelayKey)
        if savedDelay > 0 {
            triggerDelay = savedDelay
        }
    }

    // マウス監視を開始
    func startMonitoring() {
        guard isEnabled && selectedEdge != .disabled else {
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
        let mouseLocation = NSEvent.mouseLocation

        // マウスカーソルが現在あるスクリーンを取得
        guard let currentScreen = NSScreen.screens.first(where: { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        }) else { return }

        let screenFrame = currentScreen.frame

        // マウスがホットエッジにあるかチェック（マルチモニター境界を除外）
        if isInHotEdge(mouseLocation: mouseLocation, screenFrame: screenFrame, currentScreen: currentScreen) {
            // タイマーがまだ開始されていない場合のみ開始
            if triggerTimer == nil {
                triggerTimer = Timer.scheduledTimer(withTimeInterval: triggerDelay, repeats: false) { [weak self] _ in
                    self?.triggerHotEdge()
                }
            }
        } else {
            // ホットエッジから出たらタイマーをキャンセルし、クールダウンをリセット
            triggerTimer?.invalidate()
            triggerTimer = nil
            lastTriggered = nil  // クールダウンをリセット
        }
    }

    // マウスがホットエッジにあるかチェック（マルチモニター境界を除外）
    private func isInHotEdge(mouseLocation: CGPoint, screenFrame: CGRect, currentScreen: NSScreen) -> Bool {
        // マウスがエッジ付近にいるかチェック
        let isNearEdge: Bool
        switch selectedEdge {
        case .top:
            isNearEdge = mouseLocation.y >= screenFrame.maxY - edgeThreshold
        case .bottom:
            isNearEdge = mouseLocation.y <= screenFrame.minY + edgeThreshold
        case .left:
            isNearEdge = mouseLocation.x <= screenFrame.minX + edgeThreshold
        case .right:
            isNearEdge = mouseLocation.x >= screenFrame.maxX - edgeThreshold
        case .disabled:
            return false
        }

        // エッジ付近にいない場合は早期リターン
        guard isNearEdge else { return false }

        // マルチモニター境界かどうかをチェック
        // 他のスクリーンとの境界である場合はfalseを返す
        if hasAdjacentScreen(currentScreen: currentScreen, edge: selectedEdge) {
            return false
        }

        return true
    }

    // 指定したエッジに隣接するスクリーンがあるかチェック
    private func hasAdjacentScreen(currentScreen: NSScreen, edge: HotEdge) -> Bool {
        let currentFrame = currentScreen.frame
        let adjacencyThreshold: CGFloat = 10.0  // 隣接判定の閾値

        for screen in NSScreen.screens where screen != currentScreen {
            let otherFrame = screen.frame

            switch edge {
            case .top:
                // 上エッジ: 他のスクリーンの下端が現在のスクリーンの上端と接している
                if abs(otherFrame.minY - currentFrame.maxY) < adjacencyThreshold {
                    // X座標が重なっているかチェック
                    if otherFrame.maxX > currentFrame.minX && otherFrame.minX < currentFrame.maxX {
                        return true
                    }
                }
            case .bottom:
                // 下エッジ: 他のスクリーンの上端が現在のスクリーンの下端と接している
                if abs(otherFrame.maxY - currentFrame.minY) < adjacencyThreshold {
                    // X座標が重なっているかチェック
                    if otherFrame.maxX > currentFrame.minX && otherFrame.minX < currentFrame.maxX {
                        return true
                    }
                }
            case .left:
                // 左エッジ: 他のスクリーンの右端が現在のスクリーンの左端と接している
                if abs(otherFrame.maxX - currentFrame.minX) < adjacencyThreshold {
                    // Y座標が重なっているかチェック
                    if otherFrame.maxY > currentFrame.minY && otherFrame.minY < currentFrame.maxY {
                        return true
                    }
                }
            case .right:
                // 右エッジ: 他のスクリーンの左端が現在のスクリーンの右端と接している
                if abs(otherFrame.minX - currentFrame.maxX) < adjacencyThreshold {
                    // Y座標が重なっているかチェック
                    if otherFrame.maxY > currentFrame.minY && otherFrame.minY < currentFrame.maxY {
                        return true
                    }
                }
            case .disabled:
                return false
            }
        }

        return false
    }

    // ホットエッジをトリガー
    private func triggerHotEdge() {
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
    func updateSettings(edge: HotEdge, enabled: Bool) {
        selectedEdge = edge
        isEnabled = enabled
        saveSettings()

        // 監視を再開
        if enabled && edge != .disabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    // エッジ判定幅を更新
    func updateEdgeThreshold(_ threshold: CGFloat) {
        edgeThreshold = threshold
        saveSettings()
    }

    // トリガー遅延時間を更新
    func updateTriggerDelay(_ delay: TimeInterval) {
        triggerDelay = delay
        saveSettings()
    }
}
