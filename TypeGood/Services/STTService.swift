import Foundation

/// 語音轉文字服務協議
protocol STTService {
    /// 辨識音訊資料為文字
    /// - Parameters:
    ///   - audioData: WAV 格式音訊資料
    ///   - language: 語言提示（如 "zh"）
    ///   - prompt: 上下文提示（幫助 Whisper 理解語境）
    /// - Returns: 辨識結果
    func transcribe(audioData: Data, language: String?, prompt: String?) async throws -> TranscriptionResult
}

/// STT 服務錯誤
enum STTError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    case emptyAudio

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "未設定 API Key"
        case .invalidResponse: return "API 回應格式錯誤"
        case .apiError(let msg): return "API 錯誤：\(msg)"
        case .networkError(let err): return "網路錯誤：\(err.localizedDescription)"
        case .emptyAudio: return "音訊資料為空"
        }
    }
}

/// STT 服務工廠
enum STTServiceFactory {
    static func create(for provider: APIProvider) -> STTService {
        switch provider {
        case .groq: return GroqWhisperService()
        case .openai: return OpenAIWhisperService()
        }
    }
}
