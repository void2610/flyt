//
//  my_first_appApp.swift
//  my-first-app
//
//  Created by Izumi Shuya on 2025/10/21.
//

import SwiftUI
import SwiftData

@main
struct my_first_appApp: App {
    // AppDelegateを設定
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Note.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        // 見えないダミーウィンドウ（ModelContextの初期化用）
        WindowGroup {
            InitializerView()
                .frame(width: 0, height: 0)
                .onAppear {
                    // AppDelegateにModelContextを渡してウィンドウを初期化
                    appDelegate.initializeWindow(modelContext: sharedModelContainer.mainContext)

                    // ダミーウィンドウを非表示
                    if let window = NSApplication.shared.windows.first {
                        window.setIsVisible(false)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
    }
}

// 初期化専用のダミービュー
struct InitializerView: View {
    var body: some View {
        EmptyView()
    }
}
