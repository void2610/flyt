//
//  SyncSettingsTab.swift
//  Flyt
//
//  同期設定タブ
//

import SwiftUI

struct SyncSettingsTab: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject var syncManager = SyncManager.shared

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var hasCheckedAuth = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("アカウント同期")
                    .font(.title2)
                    .fontWeight(.semibold)

                if authManager.isAuthenticated {
                    // ログイン済みの表示
                    authenticatedView
                } else {
                    // 未ログインの表示
                    unauthenticatedView
                }

                Divider()
                    .padding(.vertical, 8)

                // 同期状態の表示
                syncStatusView
            }
            .padding(30)
            .frame(maxWidth: 450)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            // 設定画面を開いたときに一度だけ認証状態を確認
            if !hasCheckedAuth {
                hasCheckedAuth = true
                let hasUserLoggedIn = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasUserLoggedIn)
                if hasUserLoggedIn {
                    Task {
                        await authManager.checkAuthStatus()
                        authManager.startAuthStateListener()
                        if authManager.isAuthenticated {
                            syncManager.startSync()
                        }
                    }
                }
            }
        }
    }

    // ログイン済みビュー
    private var authenticatedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                Text("ログイン中")
                    .font(.headline)
                    .foregroundColor(.green)
            }

            // ユーザー情報
            if let email = authManager.userEmail {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("アカウント")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(email)
                            .font(.body)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
                )
            }

            // ログアウトボタン
            Button(action: {
                Task {
                    do {
                        try await authManager.signOut()
                        syncManager.stopSync()
                    } catch {
                        errorMessage = "ログアウトに失敗しました: \(error.localizedDescription)"
                    }
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("ログアウト")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // 未ログインビュー
    private var unauthenticatedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cloud.slash")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Text("未ログイン")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Googleアカウントでログインすると、複数のデバイス間でセッション数を同期できます。")
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 8)

            // ログインボタン
            Button(action: {
                isSigningIn = true
                errorMessage = nil
                Task {
                    do {
                        try await authManager.signInWithGoogle()
                        // ログイン成功後、同期を開始
                        syncManager.startSync()
                    } catch {
                        errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
                    }
                    isSigningIn = false
                }
            }) {
                HStack {
                    if isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "person.badge.key.fill")
                    }
                    Text(isSigningIn ? "ログイン中..." : "Googleでログイン")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSigningIn)

            // エラーメッセージ
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
    }

    // 同期状態ビュー
    private var syncStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("同期状態")
                .font(.headline)

            // 同期中インジケーター
            if syncManager.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("同期中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // 最終同期時刻
            if let lastSyncDate = syncManager.lastSyncDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("最終同期:")
                    Spacer()
                    Text(formatDate(lastSyncDate))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            // 同期メッセージ
            if !syncManager.lastSyncMessage.isEmpty {
                HStack {
                    if syncManager.lastSyncMessage.contains("✅") {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if syncManager.lastSyncMessage.contains("⚠️") || syncManager.lastSyncMessage.contains("❌") {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Text(syncManager.lastSyncMessage)
                        .font(.caption)
                        .lineLimit(3)
                }
            }

            // 同期エラー
            if let syncError = syncManager.syncError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("同期エラー:")
                    Text(syncError)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }

            // 手動同期ボタン
            if authManager.isAuthenticated {
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await syncManager.syncFromCloud()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("クラウドから取得")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncManager.isSyncing)

                    Button(action: {
                        let sessionCount = PomodoroManager.shared.sessionCount
                        syncManager.syncToCloud(sessionCount: sessionCount)
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                            Text("アップロード")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(syncManager.isSyncing)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.3))
        )
    }

    // 日付フォーマット
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    SyncSettingsTab()
}
