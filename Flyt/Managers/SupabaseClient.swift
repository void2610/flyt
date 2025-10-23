//
//  SupabaseClient.swift
//  Flyt
//
//  Supabaseクライアントの初期化と管理
//

import Foundation
import Supabase
import Auth

class SupabaseClientWrapper {
    // シングルトンインスタンス
    static let shared = SupabaseClientWrapper()

    // Supabaseクライアント（遅延初期化）
    private var _client: Supabase.SupabaseClient?

    var client: Supabase.SupabaseClient? {
        if _client == nil {
            initializeClient()
        }
        return _client
    }

    // Supabaseが設定されているかどうか
    var isConfigured: Bool {
        return true // 設定は常に有効（遅延初期化）
    }

    private init() {
    }

    private func initializeClient() {
        let supabaseURL = "https://pryguaqegitnbswksoqv.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeWd1YXFlZ2l0bmJzd2tzb3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExOTI5MTAsImV4cCI6MjA3Njc2ODkxMH0.LOUG_EJQOpzzXozognwtibOlt92rIS_Q2fPIduPGoYw"

        // Supabaseクライアントを初期化
        guard let url = URL(string: supabaseURL) else {
            self._client = nil
            return
        }

        // キーチェーンではなくUserDefaultsを使用するように設定
        self._client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: .init(
                auth: .init(
                    storage: UserDefaultsSessionStorage()
                )
            )
        )
    }
}

// UserDefaultsを使用したセッションストレージ
class UserDefaultsSessionStorage: AuthLocalStorage {
    private let key = "supabase.auth.session"

    func store(key: String, value: Data) throws {
        UserDefaults.standard.set(value, forKey: key)
    }

    func retrieve(key: String) throws -> Data? {
        return UserDefaults.standard.data(forKey: key)
    }

    func remove(key: String) throws {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
