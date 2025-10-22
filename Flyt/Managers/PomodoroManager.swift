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

    // タイマー設定（分単位）
    @Published var workDurationMinutes: Int = 30 {
        didSet {
            UserDefaults.standard.set(workDurationMinutes, forKey: "workDurationMinutes")
            // 待機中の場合は時間を更新
            if state == .idle {
                remainingSeconds = workDurationMinutes * 60
            }
        }
    }
    @Published var restDurationMinutes: Int = 10 {
        didSet {
            UserDefaults.standard.set(restDurationMinutes, forKey: "restDurationMinutes")
        }
    }

    // タイマー
    private var timer: Timer?

    private init() {
        // UserDefaultsから設定を読み込み
        let savedWork = UserDefaults.standard.integer(forKey: "workDurationMinutes")
        let savedRest = UserDefaults.standard.integer(forKey: "restDurationMinutes")

        if savedWork > 0 {
            workDurationMinutes = savedWork
        }
        if savedRest > 0 {
            restDurationMinutes = savedRest
        }

        // 初期化時は作業時間を設定
        remainingSeconds = workDurationMinutes * 60
    }

    // タイマーを開始
    func start() {
        guard !isRunning else { return }

        // 待機中の場合は作業モードから開始
        if state == .idle {
            state = .working
            remainingSeconds = workDurationMinutes * 60
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
        remainingSeconds = workDurationMinutes * 60
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
            remainingSeconds = restDurationMinutes * 60

        case .resting:
            // 休憩完了 → 作業へ
            state = .working
            remainingSeconds = workDurationMinutes * 60

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
            totalSeconds = workDurationMinutes * 60
        case .resting:
            totalSeconds = restDurationMinutes * 60
        case .idle:
            totalSeconds = workDurationMinutes * 60
        }

        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
}
