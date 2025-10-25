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
            UserDefaults.standard.set(workDurationMinutes, forKey: UserDefaultsKeys.workDurationMinutes)
            // 待機中の場合は時間を更新
            if state == .idle {
                remainingSeconds = workDurationMinutes * 60
            }
        }
    }
    @Published var restDurationMinutes: Int = 10 {
        didSet {
            UserDefaults.standard.set(restDurationMinutes, forKey: UserDefaultsKeys.restDurationMinutes)
        }
    }

    // タイマー
    private var timer: Timer?

    // 日付リセット用タイマー
    private var midnightTimer: Timer?

    private init() {
        // UserDefaultsから設定を読み込み
        let savedWork = UserDefaults.standard.integer(forKey: UserDefaultsKeys.workDurationMinutes)
        let savedRest = UserDefaults.standard.integer(forKey: UserDefaultsKeys.restDurationMinutes)

        if savedWork > 0 {
            workDurationMinutes = savedWork
        }
        if savedRest > 0 {
            restDurationMinutes = savedRest
        }

        // 初期化時は作業時間を設定
        remainingSeconds = workDurationMinutes * 60

        // 前回のセッション数をチェックして、日付が変わっていたらリセット
        checkAndResetSessionCount()

        // 毎日0時にセッション数をリセットするタイマーを設定
        scheduleMidnightReset()

        // SyncManagerからのセッション数更新を受け取る
        SyncManager.shared.onSessionCountUpdated = { [weak self] newCount in
            DispatchQueue.main.async {
                self?.sessionCount = newCount
                UserDefaults.standard.set(newCount, forKey: UserDefaultsKeys.sessionCount)
            }
        }
    }

    // セッション数をチェックして、日付が変わっていたらリセット
    private func checkAndResetSessionCount() {
        let lastResetDate = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastResetDate)
        let todayString = getTodayString()

        if lastResetDate != todayString {
            // 日付が変わっている場合はリセット
            sessionCount = 0
            UserDefaults.standard.set(todayString, forKey: UserDefaultsKeys.lastResetDate)
        } else {
            // 同じ日の場合は保存されたセッション数を復元
            let savedCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionCount)
            sessionCount = savedCount
        }
    }

    // 今日の日付文字列を取得
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // 0時にリセットするタイマーを設定
    private func scheduleMidnightReset() {
        let calendar = Calendar.current
        let now = Date()

        // 次の0時を計算
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           let nextMidnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) {

            let timeInterval = nextMidnight.timeIntervalSince(now)

            // 次の0時にセッション数をリセット
            midnightTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.resetSessionCount()
                // 次の日のタイマーを設定
                self?.scheduleMidnightReset()
            }
        }
    }

    // セッション数のみをリセット
    func resetSessionCount() {
        sessionCount = 0
        UserDefaults.standard.set(getTodayString(), forKey: UserDefaultsKeys.lastResetDate)
        UserDefaults.standard.set(0, forKey: UserDefaultsKeys.sessionCount)
        // 同期関連のタイムスタンプもクリア
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastUpdated)
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
        // タイマーを停止
        pause()

        // ウィンドウを最前面に表示
        showWindow()

        switch state {
        case .working:
            // 作業完了サウンドを再生
            SoundManager.shared.playWorkCompletionSound()

            // 作業完了 → 休憩へ（一時停止状態）
            sessionCount += 1
            // セッション数を保存
            UserDefaults.standard.set(sessionCount, forKey: UserDefaultsKeys.sessionCount)

            // クラウドに同期
            SyncManager.shared.syncToCloud(sessionCount: sessionCount)

            state = .resting
            remainingSeconds = restDurationMinutes * 60

        case .resting:
            // 休憩完了サウンドを再生
            SoundManager.shared.playRestCompletionSound()

            // 休憩完了 → 作業へ（一時停止状態）
            state = .working
            remainingSeconds = workDurationMinutes * 60

        case .idle:
            // 何もしない
            break
        }
    }

    // ウィンドウを表示
    private func showWindow() {
        DispatchQueue.main.async {
            WindowManager.shared.showWindow()
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
