//
//  SupabaseClient.swift
//  Flyt
//
//  Supabaseクライアントの初期化と管理
//

import Foundation
import Supabase

class SupabaseClientWrapper {
    // シングルトンインスタンス
    static let shared = SupabaseClientWrapper()

    // Supabaseクライアント（オプショナル）
    let client: Supabase.SupabaseClient?

    // Supabaseが設定されているかどうか
    var isConfigured: Bool {
        return client != nil
    }

    private init() {
        let supabaseURL = "https://pryguaqegitnbswksoqv.supabase.co"
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeWd1YXFlZ2l0bmJzd2tzb3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExOTI5MTAsImV4cCI6MjA3Njc2ODkxMH0.LOUG_EJQOpzzXozognwtibOlt92rIS_Q2fPIduPGoYw"

        // Supabaseクライアントを初期化
        guard let url = URL(string: supabaseURL) else {
            self.client = nil
            return
        }

        self.client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey
        )
    }
}
