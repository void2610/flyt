//
//  MenuBarManager.swift
//  Flyt
//
//  メニューバーアイコンとメニューを管理するクラス
//

import AppKit
import Combine

class MenuBarManager {
    // シングルトンインスタンス
    static let shared = MenuBarManager()

    // ステータスバーアイテム
    private var statusItem: NSStatusItem?

    // HotKeyManagerの変更を監視
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // HotKeyManagerの変更を監視してメニューを更新
        HotKeyManager.shared.$modifierFlags
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)

        HotKeyManager.shared.$keyCode
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)

        // PomodoroManagerの変更を監視してアイコンを更新
        PomodoroManager.shared.$remainingSeconds
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)

        PomodoroManager.shared.$isRunning
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }

    // メニューバーアイコンをセットアップ
    func setupMenuBar() {
        // ステータスバーアイテムを作成（初期はアイコン用の標準幅）
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        // アイコンを設定（SF Symbolsを使用）
        if let image = NSImage(systemSymbolName: "text.book.closed", accessibilityDescription: "Flyt") {
            image.isTemplate = true // テンプレートモードでダークモード対応
            button.image = image
        }

        // メニューを構築
        updateMenu()
    }

    // メニューを更新
    private func updateMenu() {
        // メニューを作成
        let menu = NSMenu()

        // 現在のホットキーを取得
        let hotKeyString = HotKeyManager.shared.getHotKeyString()

        // タイマーを表示/非表示
        let toggleItem = NSMenuItem(
            title: "タイマーを表示/非表示",
            action: #selector(toggleTimerWindow),
            keyEquivalent: ""
        )
        toggleItem.target = self

        // ホットキーの表示を右側に追加
        let attributedTitle = NSMutableAttributedString(string: "タイマーを表示/非表示")
        let spacing = NSMutableAttributedString(string: "\t")
        let hotKey = NSMutableAttributedString(
            string: hotKeyString,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor]
        )
        attributedTitle.append(spacing)
        attributedTitle.append(hotKey)
        toggleItem.attributedTitle = attributedTitle

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

    // タイマーウィンドウを表示/非表示
    @objc private func toggleTimerWindow() {
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

    // メニューバーアイコンを更新（タイマー実行中はテキスト表示、停止中はアイコン表示）
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let pomodoroManager = PomodoroManager.shared

        if pomodoroManager.isRunning {
            // タイマー実行中：テキスト表示（幅を45に変更）
            statusItem?.length = 45
            button.image = nil
            button.title = pomodoroManager.getTimeString()
        } else {
            // タイマー停止中：アイコン表示（幅を標準に戻す）
            statusItem?.length = NSStatusItem.squareLength
            button.title = ""
            if let image = NSImage(systemSymbolName: "text.book.closed", accessibilityDescription: "Flyt") {
                image.isTemplate = true
                button.image = image
            }
        }
    }
}
