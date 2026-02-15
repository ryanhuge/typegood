import SwiftUI

/// 選單列彈出面板
struct MenuBarView: View {
    private let pipeline = TranscriptionPipeline.shared
    private let settingsStore = SettingsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundStyle(pipeline.state.isRecording ? .red : .accentColor)
                Text("TypeGood")
                    .font(.headline)
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // 狀態顯示
            statusSection

            Divider()

            // 快捷鍵提示
            HStack {
                Image(systemName: "keyboard")
                Text("按住右側 ⌘ 說話")
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .foregroundStyle(.secondary)

            Divider()

            // API 狀態
            apiStatusSection

            Divider()

            // 操作按鈕
            VStack(spacing: 4) {
                Button {
                    AppDelegate.shared.openSettings()
                } label: {
                    Label("偏好設定...", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.vertical, 4)

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("結束 TypeGood", systemImage: "power")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 320)
    }

    // MARK: - 狀態區

    private var statusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(pipeline.state.statusText)
                    .font(.subheadline)
                Spacer()

                if pipeline.state.isRecording {
                    // 音量指示
                    AudioLevelView(level: pipeline.audioRecorder.currentLevel)
                        .frame(width: 60, height: 16)
                }
            }

            if let result = pipeline.lastResult {
                VStack(alignment: .leading, spacing: 6) {
                    // 原始文字
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Whisper 原始")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(result.rawText)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundStyle(.secondary)
                    }

                    // 處理後文字
                    if result.processedText != result.rawText {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("LLM 修正")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Text(result.processedText)
                                .font(.caption)
                                .lineLimit(2)
                        }
                    }

                    HStack {
                        Text(result.provider.displayName)
                        Text("·")
                        Text(String(format: "%.1f 秒", result.duration))
                        if settingsStore.settings.enableLLMPostProcessing {
                            Text("·")
                            Text("LLM")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }

    private var statusColor: Color {
        switch pipeline.state {
        case .idle: return .green
        case .recording: return .red
        case .processing: return .orange
        case .completed: return .blue
        case .error: return .red
        }
    }

    // MARK: - API 狀態

    private var apiStatusSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("STT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Groq Whisper")
                    .font(.caption)
                Circle()
                    .fill(settingsStore.apiKey(for: .groq) != nil ? .green : .red)
                    .frame(width: 6, height: 6)
            }
            HStack {
                Text("LLM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("OpenAI \(APIProvider.openai.llmModelName)")
                    .font(.caption)
                Circle()
                    .fill(settingsStore.apiKey(for: .openai) != nil ? .green : .red)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

/// 音量指示條
struct AudioLevelView: View {
    var level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 3)
                    .fill(level > 0.7 ? Color.red : Color.green)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .animation(.easeOut(duration: 0.05), value: level)
            }
        }
    }
}
