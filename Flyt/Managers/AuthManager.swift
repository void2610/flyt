//
//  AuthManager.swift
//  Flyt
//
//  Google認証の管理
//

import Foundation
import Supabase
import AuthenticationServices
import Combine

class AuthManager: ObservableObject {
    // シングルトンインスタンス
    static let shared = AuthManager()

    // 認証状態
    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String?
    @Published var userId: String?

    // Supabaseクライアント
    private var supabase: Supabase.SupabaseClient? {
        return SupabaseClientWrapper.shared.client
    }

    // 認証状態変更の監視用
    private var authStateTask: Task<Void, Never>?

    private init() {
        // Supabaseが設定されている場合のみ初期化
        guard SupabaseClientWrapper.shared.isConfigured else {
            print("⚠️ Supabaseが設定されていないため、認証機能は無効です")
            return
        }

    }

    // 認証状態を確認
    @MainActor
    func checkAuthStatus() async {
        guard let supabase = supabase else {
            self.isAuthenticated = false
            return
        }

        do {
            let session = try await supabase.auth.session
            self.isAuthenticated = true
            self.userEmail = session.user.email
            self.userId = session.user.id.uuidString
        } catch {
            self.isAuthenticated = false
            self.userEmail = nil
            self.userId = nil
        }
    }

    // 認証状態の変更を監視
    func startAuthStateListener() {
        guard let supabase = supabase else { return }

        authStateTask = Task {
            for await (event, session) in await supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .signedIn:
                        if let session = session {
                            self.isAuthenticated = true
                            self.userEmail = session.user.email
                            self.userId = session.user.id.uuidString
                        }
                    case .signedOut:
                        self.isAuthenticated = false
                        self.userEmail = nil
                        self.userId = nil
                    default:
                        break
                    }
                }
            }
        }
    }

    // Googleでサインイン
    @MainActor
    func signInWithGoogle() async throws {
        guard let supabase = supabase else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabaseが設定されていません"])
        }

        // ASWebAuthenticationSessionを使用してGoogle OAuthフローを開始
        // カスタムURLスキームでリダイレクト
        guard let redirectURL = URL(string: "void2610flyt://auth-callback") else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "無効なリダイレクトURL"])
        }

        try await supabase.auth.signInWithOAuth(
            provider: .google,
            redirectTo: redirectURL
        ) { session in
            // ASWebAuthenticationSessionのカスタマイズ
            session.prefersEphemeralWebBrowserSession = false
        }

        // 認証完了後、セッション情報を更新
        await checkAuthStatus()

        // ユーザーがログインしたことを記録
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasUserLoggedIn)

        // 認証状態監視を開始（初回ログイン時のみ）
        if authStateTask == nil {
            startAuthStateListener()
        }
    }

    // サインアウト
    @MainActor
    func signOut() async throws {
        guard let supabase = supabase else {
            throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabaseが設定されていません"])
        }

        try await supabase.auth.signOut()
        self.isAuthenticated = false
        self.userEmail = nil
        self.userId = nil

        // 同期関連のUserDefaultsをクリア
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastUpdated)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasUserLoggedIn)
    }

    // クリーンアップ
    deinit {
        authStateTask?.cancel()
    }
}
