//
//  HotKeyRecorderView.swift
//  Flyt
//
//  ホットキーを記録するUIコンポーネント
//

import SwiftUI
import AppKit

// NSViewRepresentableでキーイベントをキャプチャするビュー
struct HotKeyRecorderView: View {
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text("タイマーを表示/非表示:")

            Spacer()

            Button(action: {
                isRecording = true
            }) {
                HStack {
                    if isRecording {
                        Text("キーを押してください...")
                            .foregroundColor(.secondary)
                    } else {
                        Text(hotKeyManager.getHotKeyString())
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .frame(minWidth: 120)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .overlay(
                RecorderOverlay(isRecording: $isRecording)
                    .opacity(isRecording ? 1 : 0)
            )

            Button(action: {
                // デフォルトに戻す
                hotKeyManager.setHotKey(modifierFlags: [.control], keyCode: 34)
            }) {
                Text("リセット")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
    }
}

// キーイベントをキャプチャするオーバーレイビュー
struct RecorderOverlay: NSViewRepresentable {
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onKeyPress = { modifiers, keyCode in
            // ホットキーを設定
            HotKeyManager.shared.setHotKey(modifierFlags: modifiers, keyCode: keyCode)
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

// キーイベントを受け取るNSView
class RecorderNSView: NSView {
    var onKeyPress: ((NSEvent.ModifierFlags, UInt16) -> Void)?

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        // Escapeキーで記録をキャンセル
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return
        }

        // モディファイアキーのみの場合は無視
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.isEmpty {
            return
        }

        // ホットキーを記録
        onKeyPress?(modifiers, event.keyCode)
    }

    override func draw(_ dirtyRect: NSRect) {
        // 透明な背景
        NSColor.clear.setFill()
        dirtyRect.fill()
    }
}

#Preview {
    HotKeyRecorderView()
        .padding()
}
