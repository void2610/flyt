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

    // Supabaseクライアント
    private var supabase: Supabase.SupabaseClient? {
        return SupabaseClientWrapper.shared.client
    }

    // デバイスID
    private let deviceId: String

    // リアルタイムチャンネル
    private var realtimeChannel: RealtimeChannelV2?
    private var cancellables = Set<AnyCancellable>()

    // 同期コールバック
    var onSessionCountUpdated: ((Int) -> Void)?

    private init() {
        // デバイスIDを生成または取得
        if let savedDeviceId = UserDefaults.standard.string(forKey: "deviceId") {
            self.deviceId = savedDeviceId
        } else {
            self.deviceId = UUID().uuidString
            UserDefaults.standard.set(self.deviceId, forKey: "deviceId")
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
    }

    // 同期を停止
    func stopSync() {
        Task {
            await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
        }
    }

    // クラウドからデータを取得してローカルに反映
    @MainActor
    func syncFromCloud() async {
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
                // ローカルのデータと比較して、より新しいものを採用
                let localLastUpdated = UserDefaults.standard.object(forKey: "lastUpdated") as? Date ?? Date.distantPast

                if sessionData.lastUpdated > localLastUpdated {
                    // クラウドのデータが新しい場合、ローカルを更新
                    onSessionCountUpdated?(sessionData.sessionCount)
                    UserDefaults.standard.set(sessionData.lastUpdated, forKey: "lastUpdated")
                }
            }

            lastSyncDate = Date()
            syncError = nil

        } catch {
            print("同期エラー: \(error)")
            syncError = error.localizedDescription
        }
    }

    // ローカルのデータをクラウドに保存
    func syncToCloud(sessionCount: Int) {
        guard SupabaseClientWrapper.shared.isConfigured else {
            Task { @MainActor in
                self.lastSyncMessage = "⚠️ Supabaseが設定されていません"
            }
            return
        }
        guard let userIdString = AuthManager.shared.userId,
              let userId = UUID(uuidString: userIdString) else {
            Task { @MainActor in
                self.lastSyncMessage = "⚠️ ログインしていません"
            }
            return
        }

        Task { @MainActor in
            self.lastSyncMessage = "📤 アップロード中... (count=\(sessionCount))"
            await performSyncToCloud(userId: userId, sessionCount: sessionCount)
        }
    }

    @MainActor
    private func performSyncToCloud(userId: UUID, sessionCount: Int) async {
        guard let supabase = supabase else {
            lastSyncMessage = "⚠️ Supabaseクライアントが取得できません"
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

            lastSyncMessage = "📝 送信中... (date=\(today), count=\(sessionCount))"

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

            UserDefaults.standard.set(now, forKey: "lastUpdated")
            lastSyncDate = Date()
            syncError = nil

            lastSyncMessage = "✅ アップロード成功 (count=\(sessionCount))"

        } catch {
            syncError = error.localizedDescription
            lastSyncMessage = "❌ エラー: \(error.localizedDescription)"
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
        await syncFromCloud()
    }

    // 今日の日付文字列を取得
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
