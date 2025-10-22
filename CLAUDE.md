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
- **フルスクリーン対応**: 全てのアプリケーションの上に表示可能

## ビルドとインストール

```bash
# リリースビルドして /Applications にインストール
bash build-and-install.sh

# または手動ビルド
xcodebuild -project Flyt.xcodeproj -scheme Flyt -configuration Release build
```

**重要**:
- アクセシビリティ権限の永続化のため、`build-and-install.sh` を使用して `/Applications` にインストールすることを推奨
- DerivedData からの実行では、ビルドごとにアクセシビリティ権限の再付与が必要になる

## 開発ワークフロー

**重要**: コードファイル（.swift）を編集した後は、必ず `bash build-and-install.sh` を実行してビルドとインストールを行ってください。

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

### データ永続化

- UserDefaults を使用
  - `workDurationMinutes`: 作業時間（分）
  - `restDurationMinutes`: 休憩時間（分）
  - `sessionCount`: 完了セッション数
  - `lastResetDate`: 最後にリセットした日付（yyyy-MM-dd形式）

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
- **SettingsView.swift**: 設定画面（タブ形式）
  - **GeneralSettingsTab**: ポモドーロ設定
    - 作業時間と休憩時間の設定（TextFieldで直接入力）
    - セッション数の表示と手動リセット
    - タイマーリセットボタン
    - アプリ終了ボタン
  - **HotKeySettingsTab**: ホットキー設定
    - HotKeyRecorderView でホットキーのカスタマイズ
  - **AccessibilitySettingsTab**: アクセシビリティ権限設定
    - 権限状態の確認とシステム設定へのリンク
  - **AboutTab**: アプリ情報
    - バージョン情報と開発者情報

## 注意事項

- アクセシビリティ権限: システム設定 > プライバシーとセキュリティ > アクセシビリティ でアプリを許可
- ホットキーはユーザーが設定可能（デフォルトは Control+I、keyCode 34）
- Product Name: "Flyt", Bundle ID: "void2610.Flyt"
- 主要なマネージャークラスはすべてシングルトンパターン (WindowManager, HotKeyManager, MenuBarManager, PomodoroManager, AppState)

## フォルダ構成

```
Flyt/
├── App/
│   ├── FlytApp.swift          # アプリケーションエントリーポイント
│   ├── AppDelegate.swift      # グローバルホットキー監視
│   └── AppState.swift         # アプリケーション状態管理
├── Managers/
│   ├── WindowManager.swift    # ウィンドウ管理（タイマーと設定）
│   ├── HotKeyManager.swift    # ホットキー設定管理
│   ├── MenuBarManager.swift   # メニューバーアイコン管理
│   └── PomodoroManager.swift  # ポモドーロタイマーロジック
├── Views/
│   ├── ContentView.swift      # メインビューのラッパー
│   └── PomodoroTimerView.swift # タイマーUI
├── Settings/
│   ├── SettingsView.swift           # 設定画面のメインビュー
│   ├── GeneralSettingsTab.swift     # 一般設定タブ
│   ├── HotKeySettingsTab.swift      # ホットキー設定タブ
│   ├── AccessibilitySettingsTab.swift # アクセシビリティ設定タブ
│   └── AboutTab.swift               # アプリ情報タブ
└── Components/
    └── HotKeyRecorderView.swift     # ホットキー記録コンポーネント
```
