import Foundation

/// 語音辨識 API 供應商
enum APIProvider: String, Codable, CaseIterable, Identifiable {
    case groq = "groq"
    case openai = "openai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groq: return "Groq"
        case .openai: return "OpenAI"
        }
    }

    var baseURL: String {
        switch self {
        case .groq: return "https://api.groq.com/openai/v1/audio/transcriptions"
        case .openai: return "https://api.openai.com/v1/audio/transcriptions"
        }
    }

    var modelName: String {
        switch self {
        case .groq: return "whisper-large-v3-turbo"
        case .openai: return "whisper-1"
        }
    }

    /// Chat Completion API URL（用於 LLM 後處理）
    var chatCompletionURL: String {
        switch self {
        case .groq: return "https://api.groq.com/openai/v1/chat/completions"
        case .openai: return "https://api.openai.com/v1/chat/completions"
        }
    }

    /// LLM 模型名稱（用於語意後處理）
    var llmModelName: String {
        switch self {
        case .groq: return "llama-3.3-70b-versatile"
        case .openai: return "gpt-4o-mini"
        }
    }

    var keychainKey: String {
        return "com.typegood.apikey.\(rawValue)"
    }
}
