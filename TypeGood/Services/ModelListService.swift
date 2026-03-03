import Foundation

/// LLM 模型清單服務
enum ModelListService {

    /// OpenAI 推薦模型（適合文字整理用途）
    static let openAIModels = [
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-4.1-nano",
        "gpt-4.1-mini",
        "gpt-4.1",
        "gpt-4.2",
        "gpt-5-nano",
        "gpt-5-mini",
        "gpt-5",
        "gpt-5-pro",
        "gpt-5.1",
        "gpt-5.2",
        "gpt-5.2-pro",
        "o3-mini",
        "o4-mini",
    ]

    /// Groq 推薦模型
    static let groqModels = [
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant",
        "mixtral-8x7b-32768",
        "gemma2-9b-it",
    ]

    /// 取得指定供應商的模型清單
    static func models(for provider: APIProvider) -> [String] {
        switch provider {
        case .openai: return openAIModels
        case .groq: return groqModels
        }
    }
}
