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

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
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
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
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
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

                    Divider()

                    // 本文入力
                    TextEditor(text: Binding(
                        get: { selectedNote.content },
                        set: { newValue in
                            selectedNote.content = newValue
                            selectedNote.updatedAt = Date()
                        }
                    ))
                    .font(.body)
                    .padding(20)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                    Divider()

                    // 更新日時と文字数表示
                    HStack {
                        Text("更新: \(selectedNote.updatedAt, formatter: dateFormatter)")
                        Spacer()
                        Text("文字数: \(selectedNote.content.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                }
                .toolbar {
                    Button(role: .destructive, action: {
                        deleteNote(selectedNote)
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                }
                .id(selectedNote.id) // メモが変わったらビューを再生成
            } else {
                // メモが選択されていない場合
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("メモを選択してください")
                        .font(.title3)
                        .foregroundColor(.secondary)
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
        // 削除前に次に選択するメモを決定
        if selectedNote?.id == note.id {
            // 削除するメモが選択中の場合、別のメモを選択
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                if index > 0 {
                    // 一つ前のメモを選択
                    selectedNote = notes[index - 1]
                } else if notes.count > 1 {
                    // 最初のメモを削除する場合は次のメモを選択
                    selectedNote = notes[1]
                } else {
                    // 最後のメモを削除する場合は選択を解除
                    selectedNote = nil
                }
            }
        }
        modelContext.delete(note)
    }

    // 日付フォーマッター
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    ContentView()
}
