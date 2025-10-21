//
//  MenuBarManager.swift
//  Flyt
//
//  メニューバーアイコンとメニューを管理するクラス
//

import AppKit

class MenuBarManager {
    // シングルトンインスタンス
    static let shared = MenuBarManager()

    // ステータスバーアイテム
    private var statusItem: NSStatusItem?

    private init() {}

    // メニューバーアイコンをセットアップ
    func setupMenuBar() {
        // ステータスバーアイテムを作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        // アイコンを設定（SF Symbolsを使用）
        if let image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Flyt") {
            image.isTemplate = true // テンプレートモードでダークモード対応
            button.image = image
        }

        // メニューを作成
        let menu = NSMenu()

        // メモを表示/非表示
        let toggleItem = NSMenuItem(
            title: "メモを表示/非表示",
            action: #selector(toggleNoteWindow),
            keyEquivalent: "i"
        )
        toggleItem.keyEquivalentModifierMask = [.control]
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // 設定
        let settingsItem = NSMenuItem(
            title: "設定...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 終了
        let quitItem = NSMenuItem(
            title: "Flytを終了",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // メニューをステータスアイテムに設定
        statusItem?.menu = menu
    }

    // メモウィンドウを表示/非表示
    @objc private func toggleNoteWindow() {
        WindowManager.shared.toggleWindow()
    }

    // 設定ウィンドウを開く
    @objc private func openSettings() {
        WindowManager.shared.showSettingsWindow()
    }

    // アプリを終了
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
