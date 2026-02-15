import Foundation

/// 詞彙庫本地存儲
@Observable
final class VocabularyStore {
    static let shared = VocabularyStore()

    private let fileManager = FileManager.default
    var library: VocabularyLibrary

    private var storageURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeGood", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("vocabulary.json")
    }

    private init() {
        if let data = try? Data(contentsOf: VocabularyStore.defaultStorageURL()),
           let decoded = try? JSONDecoder().decode(VocabularyLibrary.self, from: data) {
            self.library = decoded
        } else {
            self.library = VocabularyLibrary()
            loadDefaultVocabulary()
        }
    }

    private static func defaultStorageURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TypeGood", isDirectory: true)
        return appDir.appendingPathComponent("vocabulary.json")
    }

    /// 載入內建預設詞彙
    private func loadDefaultVocabulary() {
        if let url = Bundle.main.url(forResource: "default_vocabulary", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([VocabularyEntry].self, from: data) {
            library.entries = decoded
            save()
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(library) {
            try? data.write(to: storageURL, options: .atomic)
        }
    }

    func add(source: String, target: String, note: String = "") {
        let entry = VocabularyEntry(source: source, target: target, note: note)
        library.add(entry)
        save()
    }

    func remove(at offsets: IndexSet) {
        library.remove(at: offsets)
        save()
    }

    func update(_ entry: VocabularyEntry) {
        library.update(entry)
        save()
    }

    /// 匯出詞彙庫為 JSON Data
    func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(library.entries)
    }

    /// 從 JSON Data 匯入詞彙
    func importJSON(_ data: Data, replace: Bool = false) throws {
        let entries = try JSONDecoder().decode([VocabularyEntry].self, from: data)
        if replace {
            library.entries = entries
        } else {
            library.entries.append(contentsOf: entries)
        }
        library.lastModified = Date()
        save()
    }
}
