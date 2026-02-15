import Foundation

/// API Key 安全存儲（檔案式，避免 Keychain 反覆授權問題）
///
/// 存儲位置：~/Library/Application Support/TypeGood/apikeys.json
/// 檔案權限：0600（僅本人可讀寫）
enum KeychainHelper {

    private static let directoryName = "TypeGood"
    private static let fileName = "apikeys.json"

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(directoryName).appendingPathComponent(fileName)
    }

    /// 儲存 API Key
    @discardableResult
    static func save(key: String, value: String) -> Bool {
        var keys = loadAll()
        keys[key] = value
        return writeAll(keys)
    }

    /// 讀取 API Key
    static func load(key: String) -> String? {
        let keys = loadAll()
        return keys[key]
    }

    /// 刪除 API Key
    @discardableResult
    static func delete(key: String) -> Bool {
        var keys = loadAll()
        keys.removeValue(forKey: key)
        return writeAll(keys)
    }

    /// 檢查 API Key 是否已設定
    static func hasKey(for provider: APIProvider) -> Bool {
        return load(key: provider.keychainKey) != nil
    }

    // MARK: - Private

    private static func loadAll() -> [String: String] {
        let url = storageURL
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("[TypeGood] API Key 讀取失敗: \(error)")
            return [:]
        }
    }

    private static func writeAll(_ keys: [String: String]) -> Bool {
        let url = storageURL
        let dir = url.deletingLastPathComponent()

        do {
            // 確保目錄存在
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            let data = try JSONEncoder().encode(keys)
            try data.write(to: url, options: .atomic)

            // 設定檔案權限為 0600（僅擁有者可讀寫）
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
            return true
        } catch {
            print("[TypeGood] API Key 儲存失敗: \(error)")
            return false
        }
    }
}
