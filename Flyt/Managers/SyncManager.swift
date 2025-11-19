//
//  SyncManager.swift
//  Flyt
//
//  セッションデータの同期管理
//

import Foundation
import Supabase
import Combine

// セッションデータモデル
struct SessionData: Codable {
    let id: UUID?
    let userId: UUID
    let sessionDate: String  // yyyy-MM-dd形式
    let sessionCount: Int
    let lastUpdated: Date
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionDate = "session_date"
        case sessionCount = "session_count"
        case lastUpdated = "last_updated"
        case deviceId = "device_id"
    }
}

class SyncManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = SyncManager()

    // 同期状態
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var lastSyncMessage: String = ""
    @Published var lastSyncStatus: SyncStatus = .idle

    // 同期状態の種類
    enum SyncStatus {
        case idle
        case success
        case warning
        case error
        case info
    }

    // Supabaseクライアント
    private var supabase: Supabase.SupabaseClient? {
        return SupabaseClientWrapper.shared.client
    }

    // デバイスID
    private let deviceId: String

    // リアルタイムチャンネル
    private var realtimeChannel: RealtimeChannelV2?
    private var cancellables = Set<AnyCancellable>()

    // 定期同期タイマー
    private var periodicSyncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5分ごとに同期

    // 同期コールバック
    var onSessionCountUpdated: ((Int) -> Void)?

    private init() {
        // デバイスIDを生成または取得
        if let savedDeviceId = UserDefaults.standard.string(forKey: UserDefaultsKeys.deviceId) {
            self.deviceId = savedDeviceId
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: UserDefaultsKeys.deviceId)
        }
    }

    // 同期を開始（認証後に呼び出す）
    func startSync() {
        guard SupabaseClientWrapper.shared.isConfigured else {
            return
        }

        guard AuthManager.shared.isAuthenticated else {
            return
        }

        // 初回同期
        Task {
            await syncFromCloud()
        }

        // リアルタイムリスナーを開始
        setupRealtimeListener()

        // 定期同期タイマーを開始
        startPeriodicSync()
    }

    // 同期を停止
    func stopSync() {
        Task {
            await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
        }
        stopPeriodicSync()
    }

    // クラウドからデータを取得してローカルに反映
    @MainActor
    func syncFromCloud(allowDecrease: Bool = false) async {
        guard let supabase = supabase else { return }
        guard let userId = AuthManager.shared.userId else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let today = getTodayString()

            // 今日のセッションデータを取得
            let response: [SessionData] = try await supabase
                .from("sessions")
                .select()
                .eq("user_id", value: userId)
                .eq("session_date", value: today)
                .execute()
                .value

            if let sessionData = response.first {
                // ローカルのタイムスタンプと比較
                let localLastUpdated = UserDefaults.standard.object(forKey: UserDefaultsKeys.lastUpdated) as? Date

                // ローカルデータの方が新しい場合は更新しない
                if let localTimestamp = localLastUpdated, localTimestamp > sessionData.lastUpdated {
                    lastSyncMessage = "ローカルデータの方が新しいため、取得をスキップしました"
                    lastSyncStatus = .info
                } else {
                    // 現在のローカルセッション数を取得
                    let currentSessionCount = UserDefaults.standard.integer(forKey: UserDefaultsKeys.sessionCount)

                    // セッション数が減少する場合の処理
                    if sessionData.sessionCount < currentSessionCount && !allowDecrease {
                        lastSyncMessage = "セッション数の減少を検出したため、取得をスキップしました（ローカル: \(currentSessionCount)、クラウド: \(sessionData.sessionCount)）"
                        lastSyncStatus = .info
                    } else {
                        // サーバーのデータを適用（Server as Source of Truth）
                        onSessionCountUpdated?(sessionData.sessionCount)
                        UserDefaults.standard.set(sessionData.lastUpdated, forKey: UserDefaultsKeys.lastUpdated)
                        lastSyncMessage = "クラウドからデータを取得しました（\(sessionData.sessionCount)セッション）"
                        lastSyncStatus = .success
                    }
                }
            } else {
                lastSyncMessage = "クラウドにデータがありません"
                lastSyncStatus = .info
            }

            lastSyncDate = Date()
            syncError = nil

        } catch {
            print("同期エラー: \(error)")
            syncError = error.localizedDescription
            lastSyncStatus = .error
        }
    }

    // ローカルのデータをクラウドに保存
    func syncToCloud(sessionCount: Int) {
        guard SupabaseClientWrapper.shared.isConfigured else {
            Task { @MainActor in
                self.lastSyncMessage = "Supabaseが設定されていません"
                self.lastSyncStatus = .warning
            }
            return
        }
        guard let userIdString = AuthManager.shared.userId,
              let userId = UUID(uuidString: userIdString) else {
            Task { @MainActor in
                self.lastSyncMessage = "ログインしていません"
                self.lastSyncStatus = .warning
            }
            return
        }

        Task { @MainActor in
            self.lastSyncMessage = "アップロード中..."
            self.lastSyncStatus = .info
            await performSyncToCloud(userId: userId, sessionCount: sessionCount)
        }
    }

    @MainActor
    private func performSyncToCloud(userId: UUID, sessionCount: Int) async {
        guard let supabase = supabase else {
            lastSyncMessage = "Supabaseクライアントが取得できません"
            lastSyncStatus = .warning
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let today = getTodayString()
            let now = Date()

            let sessionData = SessionData(
                id: nil,
                userId: userId,
                sessionDate: today,
                sessionCount: sessionCount,
                lastUpdated: now,
                deviceId: deviceId
            )

            // まず既存のデータを確認
            let existing: [SessionData] = try await supabase
                .from("sessions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("session_date", value: today)
                .execute()
                .value

            if let existingData = existing.first {
                // 既存データがある場合は更新
                try await supabase
                    .from("sessions")
                    .update(sessionData)
                    .eq("id", value: existingData.id?.uuidString ?? "")
                    .execute()
            } else {
                // 新規挿入
                try await supabase
                    .from("sessions")
                    .insert(sessionData)
                    .execute()
            }

            UserDefaults.standard.set(now, forKey: UserDefaultsKeys.lastUpdated)
            lastSyncDate = Date()
            syncError = nil

            lastSyncMessage = "データをアップロードしました（\(sessionCount)セッション）"
            lastSyncStatus = .success

        } catch {
            syncError = error.localizedDescription
            lastSyncMessage = error.localizedDescription
            lastSyncStatus = .error
        }
    }

    // リアルタイムリスナーを設定
    private func setupRealtimeListener() {
        guard let supabase = supabase else { return }
        guard let userIdString = AuthManager.shared.userId else { return }

        Task {
            // sessionsテーブルの変更を監視
            let channel = await supabase.realtimeV2.channel("sessions")

            // PostgreSQL Changesリスナーを設定
            let _ = await channel
                .onPostgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "sessions",
                    filter: "user_id=eq.\(userIdString)"
                ) { [weak self] action in
                    Task { @MainActor in
                        await self?.handleRealtimeChange(action)
                    }
                }

            // 購読開始
            do {
                try await channel.subscribe()
                self.realtimeChannel = channel
            } catch {
                print("リアルタイムリスナーエラー: \(error)")
            }
        }
    }

    // リアルタイム変更の処理
    @MainActor
    private func handleRealtimeChange(_ action: AnyAction) async {
        // 今のところ、定期的なポーリングで同期するシンプルな実装にする
        // Realtimeの詳細なレコード処理は今後の実装で対応
        await syncFromCloud(allowDecrease: false)
    }

    // 今日の日付文字列を取得
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // 定期同期タイマーを開始
    private func startPeriodicSync() {
        // 既存のタイマーがあれば停止
        stopPeriodicSync()

        // 新しいタイマーを開始
        periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard SupabaseClientWrapper.shared.isConfigured else { return }
            guard AuthManager.shared.isAuthenticated else { return }

            Task { @MainActor in
                await self.syncFromCloud(allowDecrease: false)
            }
        }
    }

    // 定期同期タイマーを停止
    private func stopPeriodicSync() {
        periodicSyncTimer?.invalidate()
        periodicSyncTimer = nil
    }
}
