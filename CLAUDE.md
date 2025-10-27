# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**Flyt** は、フルスクリーンアプリの上にも表示できるmacOS用ポモドーロタイマーアプリです。グローバルキーボードショートカット（Control+I）でどこからでも呼び出し可能な、フローティングタイマーウィンドウを提供します。

### 主な機能

- **ポモドーロタイマー**: 作業時間と休憩時間を管理
  - 作業時間と休憩時間は設定から変更可能（デフォルト: 作業30分、休憩10分）
  - セッション完了時に自動でウィンドウを表示
  - 次のセッションは手動で開始（自動開始しない）
- **セッションカウント**: 1日の完了セッション数を記録
  - 毎日0時に自動リセット
  - 設定画面から手動リセットも可能
  - Googleアカウントでログインしてクラウド同期が可能
- **フルスクリーン対応**: 全てのアプリケーションの上に表示可能
- **ホットキー**: グローバルキーボードショートカット（デフォルト: Control+I）でどこからでも呼び出し
- **ホットエッジ**: 画面の辺にマウスを移動してタイマーを表示（オプション）

## ビルドとインストール

```bash
# ビルドして /Applications にインストール
bash build-and-install.sh debug
```

## 開発ワークフロー

**重要**: コードファイル（.swift）を編集した後は、必ず `bash build-and-install.sh debug` を実行してビルドとインストールを行ってください。

## アーキテクチャ

### フルスクリーン対応の実装

SwiftUI の標準 Window シーンではフルスクリーンアプリの上に表示できないため、以下のアプローチを採用：

1. **WindowManager.swift**: `NSWindow` を手動作成
   - `window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))` でフルスクリーン以上の表示レベルを設定
   - `window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]` で全スペース対応
   - `NSHostingView` で SwiftUI コンテンツをラップ
   - タイマーウィンドウ（600x350）と設定ウィンドウの両方を管理（設定ウィンドウは通常のウィンドウレベル）
   - `showWindow()` メソッドでセッション完了時に自動表示

2. **AppDelegate.swift**: グローバルホットキー監視
   - ローカル (`NSEvent.addLocalMonitorForEvents`) とグローバル (`NSEvent.addGlobalMonitorForEvents`) の両方のイベントモニターを使用
   - HotKeyManager と連携してホットキーの一致を判定
   - アクセシビリティ権限が必要（初回起動時にダイアログ表示）
   - Timer による権限付与の自動検出とイベントモニターの再登録

3. **FlytApp.swift**: エントリーポイント
   - `NSApp.setActivationPolicy(.accessory)` で Dock アイコンを非表示
   - AppDelegate でウィンドウを初期化

### ホットキー管理

- **HotKeyManager.swift**: ホットキー設定の管理（シングルトン）
  - UserDefaults でモディファイアキー (modifierFlags) とキーコード (keyCode) を永続化
  - デフォルトは Control+I (keyCode 34)
  - `matches(event:)` でイベントとの一致を判定
  - `getHotKeyString()` でホットキーの表示用文字列を生成（⌃I など）

### ホットエッジ管理

- **HotEdgeManager.swift**: 画面の辺（ホットエッジ）の設定を管理（シングルトン）
  - 画面の上下左右の辺にマウスを移動してタイマーを表示
  - グローバルとローカルのマウスイベントモニターで検出
  - エッジ判定幅（edgeThreshold）とトリガー遅延時間（triggerDelay）をカスタマイズ可能
  - クールダウン機能で連続トリガーを防止

### メニューバー

- **MenuBarManager.swift**: メニューバーアイコンとメニューの管理（シングルトン）
  - SF Symbols の "text.book.closed" アイコンを使用
  - HotKeyManager の変更を Combine で監視し、メニューを自動更新
  - メニュー項目: タイマー表示/非表示、設定、終了
  - 現在のホットキーをメニューに表示

### ポモドーロタイマー管理

- **PomodoroManager.swift**: タイマーのコアロジック（シングルトン）
  - 作業時間と休憩時間の管理（UserDefaults で永続化）
  - セッション数のカウントと保存
  - 毎日0時の自動リセット機能（Timer を使用）
  - タイマーの開始/一時停止/リセット/スキップ機能
  - セッション完了時に自動でウィンドウを表示
  - 次のセッションは自動開始せず、ユーザーの操作を待つ

### クラウド同期

- **SupabaseClient.swift**: Supabaseクライアントの初期化と管理（シングルトン）
  - UserDefaultsを使用したセッションストレージ（キーチェーンではない）
  - 遅延初期化で設定の有無に関わらず動作
- **AuthManager.swift**: Google認証の管理（シングルトン）
  - ASWebAuthenticationSessionを使用したGoogle OAuth
  - カスタムURLスキーム（void2610flyt://auth-callback）でリダイレクト
  - 認証状態の変更を監視（Combineベース）
- **SyncManager.swift**: セッションデータの同期管理（シングルトン）
  - クラウドとローカルのセッション数を双方向同期
  - Server as Source of Truth（サーバーのデータを常に優先）
  - Realtime Channelで他デバイスの変更を検出
  - デバイスIDでデータの出所を追跡

### データ永続化

- **UserDefaultsKeys.swift**: UserDefaultsのキーを一元管理
  - ポモドーロ設定: `workDurationMinutes`, `restDurationMinutes`, `sessionCount`, `lastResetDate`
  - 同期関連: `lastUpdated`, `deviceId`, `hasUserLoggedIn`

### UI構造

- **ContentView.swift**: ポモドーロタイマー画面のラッパー
  - PomodoroTimerView を表示
  - Escキーでウィンドウを閉じる
- **PomodoroTimerView.swift**: メインのタイマーUI
  - シンプルなタイマー表示（100ptのモノスペースフォント）
  - 3つの円形ボタン: リセット、開始/一時停止、スキップ
  - 状態表示: 準備完了🍅作業中☕️休憩中
  - 完了セッション数の表示
  - ウィンドウサイズ: 600x350
- **SettingsView.swift**: 設定画面（横並びタブバー形式）
  - **GeneralSettingsTab**: ポモドーロ設定
    - 作業時間と休憩時間の設定（TextFieldで直接入力）
    - セッション数の表示と手動リセット
    - タイマーリセットボタン
    - アプリ終了ボタン
  - **HotKeySettingsTab**: ホットキー設定
    - HotKeyRecorderView でホットキーのカスタマイズ
  - **HotEdgeSettingsTab**: ホットエッジ設定
    - 画面の辺（上下左右）の選択と有効/無効切り替え
    - エッジ判定幅とトリガー遅延時間の調整
  - **SyncSettingsTab**: クラウド同期設定
    - Googleアカウントでのログイン/ログアウト
    - 同期状態の表示（最終同期時刻、エラー、メッセージ）
    - 手動同期ボタン（クラウドから取得、アップロード）
  - **AccessibilitySettingsTab**: アクセシビリティ権限設定
    - 権限状態の確認とシステム設定へのリンク
  - **AboutTab**: アプリ情報
    - バージョン情報と開発者情報

## 注意事項

- クラウド同期は任意で、ログインしなくてもローカルで使用可能
- Product Name: "Flyt", Bundle ID: "void2610.Flyt"
- カスタムURLスキーム: "void2610flyt://auth-callback"（Google OAuth用）
- 主要なマネージャークラスはすべてシングルトンパターン (WindowManager, HotKeyManager, HotEdgeManager, MenuBarManager, PomodoroManager, AppState, AuthManager, SyncManager, SupabaseClientWrapper)
