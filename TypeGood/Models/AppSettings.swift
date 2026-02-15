import Foundation

/// 應用程式設定
struct AppSettings: Codable {
    init() {}

    /// 目前使用的 API 供應商
    var activeProvider: APIProvider = .groq

    /// 主要辨識語言
    var primaryLanguage: SupportedLanguage = .zhHant

    /// 是否啟用中英混合模式
    var mixedLanguageMode: Bool = true

    /// 中英文之間自動加空格
    var autoSpaceBetweenCJKAndLatin: Bool = true

    /// 標點符號偏好
    var punctuationStyle: PunctuationStyle = .fullWidth

    /// 全域快捷鍵修飾鍵
    var hotkeyModifiers: UInt = 0x00080000 // NSEvent.ModifierFlags.option

    /// 全域快捷鍵鍵碼
    var hotkeyKeyCode: UInt16 = 54 // Right Command

    /// 是否開機自啟動
    var launchAtLogin: Bool = false

    /// 是否播放音效
    var playSoundEffects: Bool = true

    /// Whisper prompt 模板
    var whisperPrompt: String = "繁體中文語音輸入，可能包含英文單字如 API、iPhone、React、TypeScript、macOS 等技術術語。"

    /// 錄音後自動送出的延遲（秒）
    var autoSendDelay: Double = 0.3

    /// 是否啟用 LLM 語意後處理
    var enableLLMPostProcessing: Bool = true

    /// LLM 使用的 API 供應商（獨立於語音辨識供應商）
    var llmProvider: APIProvider = .openai

    /// LLM 後處理系統提示詞
    var llmSystemPrompt: String = AppSettings.defaultLLMPrompt

    static let defaultLLMPrompt = """
        你是語音輸入的改寫助手。使用者透過語音輸入文字，你要理解他的意思，然後用通順的書面語重新寫出來。

        規則：
        1. 先理解語意，再用清晰的書面中文改寫，去除口語贅詞（嗯、那個、就是說）
        2. 使用繁體中文，不要用簡體
        3. 加上適當的標點符號，讓句子結構清晰
        4. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
        5. 保持原意，但可以調整語序和用詞讓表達更精確
        6. 直接輸出改寫後的文字，不要加任何解釋
        """

    /// 自訂解碼器，確保新增欄位在舊設定檔中有預設值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeProvider = try container.decodeIfPresent(APIProvider.self, forKey: .activeProvider) ?? .groq
        primaryLanguage = try container.decodeIfPresent(SupportedLanguage.self, forKey: .primaryLanguage) ?? .zhHant
        mixedLanguageMode = try container.decodeIfPresent(Bool.self, forKey: .mixedLanguageMode) ?? true
        autoSpaceBetweenCJKAndLatin = try container.decodeIfPresent(Bool.self, forKey: .autoSpaceBetweenCJKAndLatin) ?? true
        punctuationStyle = try container.decodeIfPresent(PunctuationStyle.self, forKey: .punctuationStyle) ?? .fullWidth
        hotkeyModifiers = try container.decodeIfPresent(UInt.self, forKey: .hotkeyModifiers) ?? 0x00080000
        hotkeyKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .hotkeyKeyCode) ?? 54
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        playSoundEffects = try container.decodeIfPresent(Bool.self, forKey: .playSoundEffects) ?? true
        whisperPrompt = try container.decodeIfPresent(String.self, forKey: .whisperPrompt) ?? "繁體中文語音輸入，可能包含英文單字如 API、iPhone、React、TypeScript、macOS 等技術術語。"
        autoSendDelay = try container.decodeIfPresent(Double.self, forKey: .autoSendDelay) ?? 0.3
        enableLLMPostProcessing = try container.decodeIfPresent(Bool.self, forKey: .enableLLMPostProcessing) ?? true
        llmProvider = try container.decodeIfPresent(APIProvider.self, forKey: .llmProvider) ?? .openai
        llmSystemPrompt = try container.decodeIfPresent(String.self, forKey: .llmSystemPrompt) ?? AppSettings.defaultLLMPrompt
    }
}

/// 支援的語言
enum SupportedLanguage: String, Codable, CaseIterable, Identifiable {
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case en = "en"
    case ja = "ja"
    case ko = "ko"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhHant: return "繁體中文"
        case .zhHans: return "簡體中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    /// Whisper API 使用的語言代碼
    var whisperCode: String {
        switch self {
        case .zhHant, .zhHans: return "zh"
        case .en: return "en"
        case .ja: return "ja"
        case .ko: return "ko"
        }
    }

    var tag: String { rawValue }
}

/// 標點符號風格
enum PunctuationStyle: String, Codable, CaseIterable {
    case fullWidth = "fullWidth"   // 全形：，。！？
    case halfWidth = "halfWidth"   // 半形：,.!?
    case keep = "keep"             // 保持 API 回傳的原樣

    var displayName: String {
        switch self {
        case .fullWidth: return "全形標點"
        case .halfWidth: return "半形標點"
        case .keep: return "保持原樣"
        }
    }
}
