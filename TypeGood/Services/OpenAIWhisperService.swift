import Foundation

/// OpenAI Whisper API 服務
struct OpenAIWhisperService: STTService {

    func transcribe(audioData: Data, language: String?, prompt: String?) async throws -> TranscriptionResult {
        guard !audioData.isEmpty else { throw STTError.emptyAudio }

        guard let apiKey = SettingsStore.shared.apiKey(for: .openai) else {
            throw STTError.noAPIKey
        }

        let startTime = Date()

        let url = URL(string: APIProvider.openai.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 音訊檔案
        body.appendMultipart(boundary: boundary, name: "file", filename: "audio.wav", mimeType: "audio/wav", data: audioData)

        // 模型
        body.appendMultipart(boundary: boundary, name: "model", value: APIProvider.openai.modelName)

        // 語言
        if let language = language {
            body.appendMultipart(boundary: boundary, name: "language", value: language)
        }

        // 提示文字
        if let prompt = prompt {
            body.appendMultipart(boundary: boundary, name: "prompt", value: prompt)
        }

        // 回應格式
        body.appendMultipart(boundary: boundary, name: "response_format", value: "verbose_json")

        // 溫度
        body.appendMultipart(boundary: boundary, name: "temperature", value: "0.0")

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw STTError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "未知錯誤"
            throw STTError.apiError("HTTP \(httpResponse.statusCode): \(errorMsg)")
        }

        let duration = Date().timeIntervalSince(startTime)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw STTError.invalidResponse
        }

        let detectedLanguage = json["language"] as? String

        return TranscriptionResult(
            rawText: text,
            provider: .openai,
            duration: duration,
            detectedLanguage: detectedLanguage
        )
    }
}
