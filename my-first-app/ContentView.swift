import SwiftUI

// メモデータの構造体
struct Note: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var content: String
    var updatedAt: Date
}

struct ContentView: View {
    // メモのリスト
    @State private var notes: [Note] = [
        Note(title: "最初のメモ", content: "ここにメモを書いてください", updatedAt: Date())
    ]

    // 選択中のメモ
    @State private var selectedNote: Note?

    var body: some View {
        NavigationSplitView {
            // 左側: メモリスト
            List(selection: $selectedNote) {
                ForEach($notes) { $note in
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
            if let index = notes.firstIndex(where: { $0.id == selectedNote?.id }) {
                VStack(spacing: 0) {
                    // タイトル入力
                    TextField("タイトル", text: Binding(
                        get: { notes[index].title },
                        set: { newValue in
                            notes[index].title = newValue
                            notes[index].updatedAt = Date()
                        }
                    ))
                    .font(.title)
                    .padding()

                    Divider()

                    // 本文入力
                    TextEditor(text: Binding(
                        get: { notes[index].content },
                        set: { newValue in
                            notes[index].content = newValue
                            notes[index].updatedAt = Date()
                        }
                    ))
                    .padding()

                    // 更新日時と文字数表示
                    HStack {
                        Text("更新: \(notes[index].updatedAt, style: .time)")
                        Spacer()
                        Text("文字数: \(notes[index].content.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                }
                .toolbar {
                    Button(role: .destructive, action: {
                        if let selected = selectedNote {
                            deleteNote(selected)
                        }
                    }) {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(selectedNote == nil)
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
    }

    // 新規メモを追加
    private func addNewNote() {
        let newNote = Note(title: "新規メモ", content: "", updatedAt: Date())
        notes.insert(newNote, at: 0)
        selectedNote = newNote
    }

    // メモを削除
    private func deleteNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
            if selectedNote?.id == note.id {
                selectedNote = notes.first
            }
        }
    }
}

#Preview {
    ContentView()
}
