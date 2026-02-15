import Foundation

/// LLM 語意後處理器：使用大型語言模型修正語音辨識結果
struct LLMPostProcessor {

    private let provider: APIProvider
    private let apiKey: String
    private let systemPrompt: String

    init(provider: APIProvider, apiKey: String, systemPrompt: String) {
        self.provider = provider
        self.apiKey = apiKey
        self.systemPrompt = systemPrompt
    }

    /// 使用 LLM 修正辨識文字
    func process(_ text: String) async throws -> String {
        guard !text.isEmpty else { return text }

        let url = URL(string: provider.chatCompletionURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": provider.llmModelName,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.7,
            "max_tokens": 2048
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "未知錯誤"
            throw LLMError.apiError("HTTP \(httpResponse.statusCode): \(errorMsg)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        let result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? text : result
    }
}

/// LLM 後處理錯誤
enum LLMError: LocalizedError {
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "LLM API 回應格式錯誤"
        case .apiError(let msg): return "LLM API 錯誤：\(msg)"
        }
    }
}
