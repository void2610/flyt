//
//  PomodoroManager.swift
//  Flyt
//
//  ポモドーロタイマーの管理
//

import Foundation
import AppKit
import Combine

// ポモドーロの状態
enum PomodoroState {
    case idle           // 待機中
    case working        // 作業中
    case resting        // 休憩中
}

class PomodoroManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = PomodoroManager()

    // 公開プロパティ
    @Published var state: PomodoroState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var sessionCount: Int = 0
    @Published var isRunning: Bool = false

    // タイマー設定（固定）
    private let workDuration: Int = 30 * 60      // 30分
    private let restDuration: Int = 10 * 60      // 10分

    // タイマー
    private var timer: Timer?

    private init() {
        // 初期化時は作業時間を設定
        remainingSeconds = workDuration
    }

    // タイマーを開始
    func start() {
        guard !isRunning else { return }

        // 待機中の場合は作業モードから開始
        if state == .idle {
            state = .working
            remainingSeconds = workDuration
        }

        isRunning = true

        // 1秒ごとにカウントダウン
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    // タイマーを一時停止
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    // タイマーをリセット
    func reset() {
        pause()
        state = .idle
        remainingSeconds = workDuration
        sessionCount = 0
    }

    // 次のセッションにスキップ
    func skipToNext() {
        pause()
        completeCurrentSession()
    }

    // 1秒ごとの処理
    private func tick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            completeCurrentSession()
        }
    }

    // 現在のセッションを完了
    private func completeCurrentSession() {
        switch state {
        case .working:
            // 作業完了 → 休憩へ
            sessionCount += 1
            state = .resting
            remainingSeconds = restDuration

        case .resting:
            // 休憩完了 → 作業へ
            state = .working
            remainingSeconds = workDuration

        case .idle:
            // 何もしない
            break
        }

        // タイマーを継続
        if isRunning {
            // 既にタイマーが動いているので何もしない
        }
    }

    // 残り時間を文字列で取得 (MM:SS)
    func getTimeString() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // 進捗率を取得 (0.0 ~ 1.0)
    func getProgress() -> Double {
        let totalSeconds: Int
        switch state {
        case .working:
            totalSeconds = workDuration
        case .resting:
            totalSeconds = restDuration
        case .idle:
            totalSeconds = workDuration
        }

        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
}
