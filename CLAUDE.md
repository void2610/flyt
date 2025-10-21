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

2. **AppDelegate.swift**: グローバルホットキー監視
   - `NSEvent.addGlobalMonitorForEvents` でシステム全体のキー入力を監視
   - アクセシビリティ権限が必要（初回起動時にダイアログ表示）
   - Timer による権限付与の自動検出とイベントモニターの再登録

3. **FlytApp.swift**: エントリーポイント
   - `NSApp.setActivationPolicy(.accessory)` で Dock アイコンを非表示
   - ダミー WindowGroup で ModelContext を初期化し、WindowManager に渡す

### データ永続化

- SwiftData を使用
- `Note` モデル（ContentView.swift 内）: id, title, content, updatedAt
- `ModelContainer` は app レベルで作成し、WindowManager 経由で ContentView に environment として注入

### UI構造

- NavigationSplitView: 左側にメモリスト、右側にエディタ
- NSVisualEffectView (.hudWindow material) で半透明背景
- SwiftUI toolbar API を使用（NSWindow 内で sceneBridgingOptions により有効化）

## 注意事項

- アクセシビリティ権限: システム設定 > プライバシーとセキュリティ > アクセシビリティ でアプリを許可
- ホットキーコード: Control+I は `event.keyCode == 34` で検出
- Product Name: "Flyt", Bundle ID: "void2610.Flyt"
