# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

**Flyt** は、フルスクリーンアプリの上にも表示できるmacOS用メモアプリです。グローバルキーボードショートカット（Control+I）でどこからでも呼び出し可能な、フローティングノートウィンドウを提供します。

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

## アーキテクチャ

### フルスクリーン対応の実装

SwiftUI の標準 Window シーンではフルスクリーンアプリの上に表示できないため、以下のアプローチを採用：

1. **WindowManager.swift**: `NSWindow` を手動作成
   - `window.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1)` でフルスクリーン以上の表示レベルを設定
   - `window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]` で全スペース対応
   - `NSHostingView` で SwiftUI コンテンツをラップ
   - **重要**: `hostingView.sceneBridgingOptions = [.toolbars]` で SwiftUI の `.toolbar` 修飾子を NSWindow で有効化
   - メモウィンドウと設定ウィンドウの両方を管理（設定ウィンドウは通常のウィンドウレベル）

2. **AppDelegate.swift**: グローバルホットキー監視
   - ローカル (`NSEvent.addLocalMonitorForEvents`) とグローバル (`NSEvent.addGlobalMonitorForEvents`) の両方のイベントモニターを使用
   - HotKeyManager と連携してホットキーの一致を判定
   - アクセシビリティ権限が必要（初回起動時にダイアログ表示）
   - Timer による権限付与の自動検出とイベントモニターの再登録

3. **FlytApp.swift**: エントリーポイント
   - `NSApp.setActivationPolicy(.accessory)` で Dock アイコンを非表示
   - ダミー WindowGroup で ModelContext を初期化し、WindowManager に渡す

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
  - メニュー項目: メモ表示/非表示、設定、終了
  - 現在のホットキーをメニューに表示

### データ永続化

- SwiftData を使用
- `Note` モデル（ContentView.swift 内）: id, title, content, updatedAt
- `ModelContainer` は app レベルで作成し、WindowManager 経由で ContentView に environment として注入

### UI構造

- **ContentView.swift**: メインのメモ編集画面
  - NavigationSplitView: 左側にメモリスト、右側にエディタ
  - NSVisualEffectView (.hudWindow material) で半透明背景
  - SwiftUI toolbar API を使用（NSWindow 内で sceneBridgingOptions により有効化）
- **SettingsView.swift**: 設定画面
  - HotKeyRecorderView でホットキーのカスタマイズ
  - アプリ情報の表示

## 注意事項

- アクセシビリティ権限: システム設定 > プライバシーとセキュリティ > アクセシビリティ でアプリを許可
- ホットキーはユーザーが設定可能（デフォルトは Control+I、keyCode 34）
- Product Name: "Flyt", Bundle ID: "void2610.Flyt"
- 主要なマネージャークラスはすべてシングルトンパターン (WindowManager, HotKeyManager, MenuBarManager, AppState)
