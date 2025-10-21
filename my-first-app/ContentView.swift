import SwiftUI
import SwiftData

// メモデータのモデル(SwiftDataで永続化)
@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var updatedAt: Date

    init(title: String, content: String, updatedAt: Date) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
    }
}

struct ContentView: View {
    // SwiftDataからメモを取得
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    // 選択中のメモ
    @State private var selectedNote: Note?

    // アプリケーション状態
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            // 左側: メモリスト
            List(selection: $selectedNote) {
                ForEach(notes) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.content)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .tag(note)
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("メモ")
            .toolbar {
                Button(action: addNewNote) {
                    Label("新規メモ", systemImage: "square.and.pencil")
                }
            }
        } detail: {
            // 右側: メモ編集エリア
            if let selectedNote = selectedNote {
                VStack(spacing: 0) {
                    // タイトル入力
                    TextField("タイトル", text: Binding(
                        get: { selectedNote.title },
                        set: { newValue in
                            selectedNote.title = newValue
                            selectedNote.updatedAt = Date()
                        }
                    ))
                    .font(.title)
                    .padding()

                    Divider()

                    // 本文入力
                    TextEditor(text: Binding(
                        get: { selectedNote.content },
                        set: { newValue in
                            selectedNote.content = newValue
                            selectedNote.updatedAt = Date()
                        }
                    ))
                    .padding()

                    // 更新日時と文字数表示
                    HStack {
                        Text("更新: \(selectedNote.updatedAt, style: .time)")
                        Spacer()
                        Text("文字数: \(selectedNote.content.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                }
                .toolbar {
                    Button(role: .destructive, action: {
                        deleteNote(selectedNote)
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                }
            } else {
                // メモが選択されていない場合
                VStack {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("メモを選択してください")
                        .foregroundColor(.gray)
                }
            }
        }
        // Escキーで閉じる
        .onKeyPress(.escape) {
            NSApplication.shared.keyWindow?.close()
            return .handled
        }
    }
    
    // 新規メモを追加
    private func addNewNote() {
        let newNote = Note(title: "新規メモ", content: "", updatedAt: Date())
        modelContext.insert(newNote)
        selectedNote = newNote
    }

    // メモを削除
    private func deleteNote(_ note: Note) {
        modelContext.delete(note)
        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
    }
}

#Preview {
    ContentView()
}
