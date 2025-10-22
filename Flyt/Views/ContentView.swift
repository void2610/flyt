import SwiftUI

struct ContentView: View {
    var body: some View {
        PomodoroTimerView()
            // Escキーで閉じる
            .onKeyPress(.escape) {
                NSApplication.shared.keyWindow?.close()
                return .handled
            }
    }
}

#Preview {
    ContentView()
}
