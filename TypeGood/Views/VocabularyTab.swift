import SwiftUI

/// 自訂詞彙管理頁面
struct VocabularyTab: View {
    private var vocabularyStore = VocabularyStore.shared

    @State private var showAddSheet = false
    @State private var editingEntry: VocabularyEntry?
    @State private var searchText = ""
    @State private var showImportAlert = false
    @State private var importError: String?

    private var filteredEntries: [VocabularyEntry] {
        if searchText.isEmpty {
            return vocabularyStore.library.entries
        }
        return vocabularyStore.library.entries.filter {
            $0.source.localizedCaseInsensitiveContains(searchText) ||
            $0.target.localizedCaseInsensitiveContains(searchText) ||
            $0.note.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具列
            HStack {
                TextField("搜尋詞彙...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)

                Spacer()

                Text("\(vocabularyStore.library.entries.count) 筆詞彙")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }

                Menu {
                    Button("匯出詞彙庫...") { exportVocabulary() }
                    Button("匯入詞彙庫...") { importVocabulary() }
                    Divider()
                    Button("重置為預設", role: .destructive) {
                        vocabularyStore.library = VocabularyLibrary()
                        vocabularyStore.save()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()

            Divider()

            // 詞彙列表
            if filteredEntries.isEmpty {
                ContentUnavailableView {
                    Label("沒有詞彙", systemImage: "text.book.closed")
                } description: {
                    Text("點擊 + 新增自訂詞彙替換規則")
                }
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        VocabularyRow(entry: entry)
                            .onTapGesture {
                                editingEntry = entry
                            }
                    }
                    .onDelete { offsets in
                        vocabularyStore.remove(at: offsets)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            VocabularyEditSheet { entry in
                vocabularyStore.add(source: entry.source, target: entry.target, note: entry.note)
            }
        }
        .sheet(item: $editingEntry) { entry in
            VocabularyEditSheet(entry: entry) { updated in
                vocabularyStore.update(updated)
            }
        }
        .alert("匯入錯誤", isPresented: $showImportAlert, presenting: importError) { _ in
            Button("確定") {}
        } message: { error in
            Text(error)
        }
    }

    private func exportVocabulary() {
        guard let data = vocabularyStore.exportJSON() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "typegood_vocabulary.json"
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func importVocabulary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                try vocabularyStore.importJSON(data, replace: false)
            } catch {
                importError = error.localizedDescription
                showImportAlert = true
            }
        }
    }
}

/// 詞彙列表行
struct VocabularyRow: View {
    let entry: VocabularyEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(entry.source)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(entry.target)
                        .fontWeight(.medium)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Circle()
                .fill(entry.isEnabled ? .green : .gray)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 2)
    }
}

/// 詞彙編輯表單
struct VocabularyEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var source: String
    @State private var target: String
    @State private var note: String
    @State private var isEnabled: Bool

    private let existingEntry: VocabularyEntry?
    private let onSave: (VocabularyEntry) -> Void

    init(entry: VocabularyEntry? = nil, onSave: @escaping (VocabularyEntry) -> Void) {
        self.existingEntry = entry
        self.onSave = onSave
        _source = State(initialValue: entry?.source ?? "")
        _target = State(initialValue: entry?.target ?? "")
        _note = State(initialValue: entry?.note ?? "")
        _isEnabled = State(initialValue: entry?.isEnabled ?? true)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(existingEntry == nil ? "新增詞彙" : "編輯詞彙")
                .font(.headline)

            Form {
                TextField("辨識錯誤文字（來源）", text: $source)
                TextField("正確文字（目標）", text: $target)
                TextField("備註（選填）", text: $note)
                Toggle("啟用", isOn: $isEnabled)
            }

            HStack {
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button(existingEntry == nil ? "新增" : "儲存") {
                    var entry = existingEntry ?? VocabularyEntry(source: source, target: target)
                    entry.source = source
                    entry.target = target
                    entry.note = note
                    entry.isEnabled = isEnabled
                    onSave(entry)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(source.isEmpty || target.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 280)
    }
}
