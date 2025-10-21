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

    // アプリケーション状態
    @StateObject private var appState = AppState.shared

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
        // メインウィンドウ(非表示)
        WindowGroup {
            HotkeyListenerView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)

        // フローティングメモウィンドウ
        Window("Quick Note", id: "note-window") {
            ContentView()
                .frame(width: 800, height: 600)
                .background(VisualEffectBlur())
                .environmentObject(appState)
                .onAppear {
                    print("🪟 ContentView onAppear 実行")
                    // ウィンドウにIDを設定
                    if let window = NSApplication.shared.windows.last {
                        print("🔧 ウィンドウにIDを設定: note-window")
                        window.identifier = NSUserInterfaceItemIdentifier("note-window")
                        window.level = .floating
                        print("📍 ウィンドウレベルを floating に設定")
                    } else {
                        print("⚠️ ウィンドウが見つかりません")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// ホットキー通知を監視するView
struct HotkeyListenerView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleNoteWindow"))) { _ in
                print("📬 通知を受信: ToggleNoteWindow")
                print("🚀 note-windowを開きます")
                openWindow(id: "note-window")
            }
    }
}

// 半透明背景のためのVisualEffectView
struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
