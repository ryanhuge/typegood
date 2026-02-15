import SwiftUI

/// 語言設定頁面
struct LanguageSettingsTab: View {
    private var settingsStore = SettingsStore.shared

    var body: some View {
        Form {
            Section("主要語言") {
                Picker("辨識語言", selection: Bindable(settingsStore).settings.primaryLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }

                Toggle("中英文混合模式", isOn: Bindable(settingsStore).settings.mixedLanguageMode)

                Text("啟用混合模式後，Whisper 會同時辨識中文和英文內容")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("文字處理") {
                Toggle("中英文之間自動加空格", isOn: Bindable(settingsStore).settings.autoSpaceBetweenCJKAndLatin)

                Text("例如「使用React框架」→「使用 React 框架」")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("標點符號風格", selection: Bindable(settingsStore).settings.punctuationStyle) {
                    ForEach(PunctuationStyle.allCases, id: \.rawValue) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                Text("全形：，。！？　半形：,.!?　保持原樣：不轉換")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Whisper 提示詞") {
                TextEditor(text: Bindable(settingsStore).settings.whisperPrompt)
                    .frame(height: 80)
                    .font(.system(.body, design: .monospaced))

                Text("提示詞幫助 Whisper 理解語境，可加入常用專有名詞以提升辨識準確度。例如輸入「TypeGood, React, Python」，Whisper 會優先辨識這些詞彙。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("重置為預設") {
                    settingsStore.settings.whisperPrompt = AppSettings().whisperPrompt
                }
            }

            Section("LLM 語意後處理") {
                Toggle("啟用 LLM 智慧修正", isOn: Bindable(settingsStore).settings.enableLLMPostProcessing)

                Picker("LLM 供應商", selection: Bindable(settingsStore).settings.llmProvider) {
                    ForEach(APIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("使用模型")
                    Spacer()
                    Text(settingsStore.settings.llmProvider.llmModelName)
                        .foregroundStyle(.secondary)
                }

                if settingsStore.apiKey(for: settingsStore.settings.llmProvider) == nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("請先在 API 設定頁面輸入 \(settingsStore.settings.llmProvider.displayName) 的 API Key")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text("語音辨識（STT）和語意修正（LLM）可使用不同供應商。例如 Groq 做語音轉文字、OpenAI GPT 做智慧修正。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("LLM 系統提示詞") {
                TextEditor(text: Bindable(settingsStore).settings.llmSystemPrompt)
                    .frame(height: 120)
                    .font(.system(.caption, design: .monospaced))

                Text("系統提示詞決定 LLM 如何改寫文字。可依需求調整，例如改為更正式的書面語、或保留口語風格。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("重置為預設") {
                    settingsStore.settings.llmSystemPrompt = AppSettings().llmSystemPrompt
                }
            }
            .disabled(!settingsStore.settings.enableLLMPostProcessing)
            .opacity(settingsStore.settings.enableLLMPostProcessing ? 1 : 0.5)
        }
        .formStyle(.grouped)
        .padding()
    }
}
