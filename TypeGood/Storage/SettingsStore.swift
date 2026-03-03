import Foundation
import SwiftUI

/// 應用程式設定存儲（使用 UserDefaults）
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let settingsKey = "com.typegood.settings"

    var settings: AppSettings {
        didSet { save() }
    }

    private static let currentSettingsVersion = 4

    private init() {
        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = AppSettings()
        }
        migrateIfNeeded()
    }

    /// 設定遷移：當預設值更新時，自動套用到已儲存的設定
    private func migrateIfNeeded() {
        let storedVersion = defaults.integer(forKey: "com.typegood.settingsVersion")
        guard storedVersion < Self.currentSettingsVersion else { return }

        // v1 → v2: 更新 LLM 系統提示詞（修正「回應內容」而非「整理文字」的問題）
        if storedVersion < 2 {
            let oldDefaultPrompts = [
                "你是語音輸入的文字後處理助手",
                "你是一個語音輸入的文字整理助手。請將以下語音辨識的文字整理成通順的書面文字"
            ]
            let currentPrompt = settings.llmSystemPrompt
            // 如果使用者的提示詞是舊版預設（或包含舊版特徵），更新為新版
            if oldDefaultPrompts.contains(where: { currentPrompt.hasPrefix($0) }) ||
               !currentPrompt.contains("你的工作是「整理文字」，不是「回應內容」") {
                settings.llmSystemPrompt = AppSettings.defaultLLMPrompt
            }
        }

        // v2 → v3: 強化提示詞，加入問句範例防止 LLM 搶答問題
        if storedVersion < 3 {
            let currentPrompt = settings.llmSystemPrompt
            // 如果使用者的提示詞不包含問句範例（v2 預設），更新為 v3
            if !currentPrompt.contains("即使輸入是問句") {
                settings.llmSystemPrompt = AppSettings.defaultLLMPrompt
            }
        }

        // v3 → v4: 新增 llmModelName 欄位，從 APIProvider 預設值帶入
        if storedVersion < 4 {
            if settings.llmModelName.isEmpty {
                settings.llmModelName = settings.llmProvider.defaultLLMModelName
            }
        }

        defaults.set(Self.currentSettingsVersion, forKey: "com.typegood.settingsVersion")
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    func reset() {
        settings = AppSettings()
    }

    // MARK: - 便捷存取

    var activeProvider: APIProvider {
        get { settings.activeProvider }
        set { settings.activeProvider = newValue }
    }

    var primaryLanguage: SupportedLanguage {
        get { settings.primaryLanguage }
        set { settings.primaryLanguage = newValue }
    }

    var mixedLanguageMode: Bool {
        get { settings.mixedLanguageMode }
        set { settings.mixedLanguageMode = newValue }
    }

    var whisperPrompt: String {
        get { settings.whisperPrompt }
        set { settings.whisperPrompt = newValue }
    }

    /// 取得目前 API Key
    func apiKey(for provider: APIProvider? = nil) -> String? {
        let p = provider ?? settings.activeProvider
        return KeychainHelper.load(key: p.keychainKey)
    }

    /// 設定 API Key
    func setAPIKey(_ key: String, for provider: APIProvider) {
        KeychainHelper.save(key: provider.keychainKey, value: key)
    }

    /// 清除 API Key
    func clearAPIKey(for provider: APIProvider) {
        KeychainHelper.delete(key: provider.keychainKey)
    }
}
