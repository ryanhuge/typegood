import SwiftUI

/// API Key 管理設定頁面
struct APISettingsTab: View {
    private var settingsStore = SettingsStore.shared

    @State private var groqKey: String = ""
    @State private var openaiKey: String = ""
    @State private var groqKeyVisible: Bool = false
    @State private var openaiKeyVisible: Bool = false
    @State private var testingProvider: APIProvider?
    @State private var testResult: (provider: APIProvider, success: Bool, message: String)?

    var body: some View {
        Form {
            Section("語音辨識（STT）— Groq") {
                apiKeyField(
                    key: $groqKey,
                    visible: $groqKeyVisible,
                    provider: .groq,
                    placeholder: "gsk_..."
                )
                HStack {
                    Text("模型")
                    Spacer()
                    Text(APIProvider.groq.modelName)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("如何取得 Groq API Key：")
                        .font(.caption).bold()
                    Text("1. 前往 console.groq.com 註冊／登入")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("2. 左側選單點「API Keys」→「Create API Key」")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("3. 複製 gsk_ 開頭的 Key 貼到上方欄位")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Groq 提供免費額度，日常使用綽綽有餘。")
                        .font(.caption).foregroundStyle(.secondary).italic()
                    Button("開啟 Groq Console") {
                        NSWorkspace.shared.open(URL(string: "https://console.groq.com/keys")!)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
                .padding(.vertical, 2)
            }

            Section("語意修正（LLM）— OpenAI") {
                apiKeyField(
                    key: $openaiKey,
                    visible: $openaiKeyVisible,
                    provider: .openai,
                    placeholder: "sk-..."
                )
                HStack {
                    Text("模型")
                    Spacer()
                    Text(APIProvider.openai.llmModelName)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("如何取得 OpenAI API Key：")
                        .font(.caption).bold()
                    Text("1. 前往 platform.openai.com 註冊／登入")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("2. 點「API Keys」→「Create new secret key」")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("3. 複製 sk- 開頭的 Key 貼到上方欄位")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("需預先儲值（最低 $5 USD），使用 gpt-4o-mini 費用極低。")
                        .font(.caption).foregroundStyle(.secondary).italic()
                    Button("開啟 OpenAI Platform") {
                        NSWorkspace.shared.open(URL(string: "https://platform.openai.com/api-keys")!)
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
                .padding(.vertical, 2)
            }

            if let result = testResult {
                Section {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.success ? .green : .red)
                        Text(result.message)
                            .font(.caption)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadKeys()
        }
    }

    @ViewBuilder
    private func apiKeyField(key: Binding<String>, visible: Binding<Bool>, provider: APIProvider, placeholder: String) -> some View {
        HStack {
            if visible.wrappedValue {
                TextField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
            } else {
                SecureField(placeholder, text: key)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                visible.wrappedValue.toggle()
            } label: {
                Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
        }
        .onChange(of: key.wrappedValue) { _, newValue in
            if !newValue.isEmpty {
                settingsStore.setAPIKey(newValue, for: provider)
            }
        }

        HStack {
            Button("測試連線") {
                testAPI(provider: provider)
            }
            .disabled(key.wrappedValue.isEmpty || testingProvider != nil)

            if testingProvider == provider {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()

            if !key.wrappedValue.isEmpty {
                Button("清除", role: .destructive) {
                    key.wrappedValue = ""
                    settingsStore.clearAPIKey(for: provider)
                }
            }
        }
    }

    private func loadKeys() {
        groqKey = settingsStore.apiKey(for: .groq) ?? ""
        openaiKey = settingsStore.apiKey(for: .openai) ?? ""
    }

    private func testAPI(provider: APIProvider) {
        testingProvider = provider
        testResult = nil

        Task {
            do {
                switch provider {
                case .groq:
                    // Groq：測試 STT（Whisper）
                    let service = STTServiceFactory.create(for: .groq)
                    let testAudio = createSilentWAV(durationSeconds: 1)
                    let result = try await service.transcribe(audioData: testAudio, language: "zh", prompt: nil)
                    testResult = (provider, true, "Groq STT 連線成功！（\(String(format: "%.1f", result.duration))秒）")
                case .openai:
                    // OpenAI：測試 LLM（Chat Completion）
                    guard let apiKey = settingsStore.apiKey(for: .openai) else {
                        testResult = (provider, false, "OpenAI API Key 未設定")
                        break
                    }
                    let llm = LLMPostProcessor(
                        provider: .openai,
                        apiKey: apiKey,
                        systemPrompt: "回覆「OK」即可。"
                    )
                    let response = try await llm.process("測試")
                    testResult = (provider, true, "OpenAI LLM 連線成功！（回應：\(response)）")
                }
            } catch {
                testResult = (provider, false, "\(provider.displayName)：\(error.localizedDescription)")
            }
            testingProvider = nil
        }
    }

    /// 建立靜音 WAV 檔用於測試
    private func createSilentWAV(durationSeconds: Double) -> Data {
        let sampleRate: Int = 16000
        let numSamples = Int(Double(sampleRate) * durationSeconds)
        let dataSize = numSamples * 2  // 16-bit = 2 bytes per sample

        var wav = Data()
        // RIFF header
        wav.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let fileSize = UInt32(36 + dataSize)
        wav.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian, Array.init))
        wav.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        // fmt chunk
        wav.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))  // PCM
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))  // mono
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian, Array.init))
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init))  // block align
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init)) // bits per sample
        // data chunk
        wav.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian, Array.init))
        wav.append(contentsOf: [UInt8](repeating: 0, count: dataSize))

        return wav
    }
}
