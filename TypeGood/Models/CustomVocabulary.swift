import Foundation

/// 自訂詞彙項目：用於辨識後的文字替換
struct VocabularyEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    /// 辨識結果中可能出現的錯誤文字（來源）
    var source: String
    /// 要替換成的正確文字（目標）
    var target: String
    /// 是否啟用此規則
    var isEnabled: Bool = true
    /// 備註
    var note: String = ""
}

/// 詞彙庫
struct VocabularyLibrary: Codable {
    var entries: [VocabularyEntry] = []
    var lastModified: Date = Date()

    mutating func add(_ entry: VocabularyEntry) {
        entries.append(entry)
        lastModified = Date()
    }

    mutating func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        lastModified = Date()
    }

    mutating func update(_ entry: VocabularyEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            lastModified = Date()
        }
    }

    /// 取得所有啟用的替換規則
    var activeRules: [(source: String, target: String)] {
        entries.filter(\.isEnabled).map { ($0.source, $0.target) }
    }
}
