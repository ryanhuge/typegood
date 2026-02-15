import Foundation
import AppKit

/// 轉錄流水線：串接 錄音 → API 辨識 → 後處理 → 文字注入
@Observable
final class TranscriptionPipeline {
    static let shared = TranscriptionPipeline()

    let audioRecorder = AudioRecorder()
    private let hotkeyManager = HotkeyManager.shared
    private let settingsStore = SettingsStore.shared

    var state: TranscriptionState = .idle
    var lastResult: TranscriptionResult?
    var errorMessage: String?

    private var activationTimer: Timer?

    private init() {
        setupHotkey()
    }

    // MARK: - 快捷鍵設定

    private func setupHotkey() {
        hotkeyManager.onKeyDown = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onKeyUp = { [weak self] in
            self?.stopRecordingAndTranscribe()
        }
    }

    /// 啟動全域快捷鍵監聽（若權限尚未授權，會自動每 2 秒重試）
    func activate() {
        if hotkeyManager.start() {
            // 成功啟動，清除重試計時器
            activationTimer?.invalidate()
            activationTimer = nil
            if case .error = state {
                state = .idle
            }
        } else {
            state = .error("需要輔助使用權限，請在系統設定中允許")
            // 設定定時重試，等待使用者授權後自動啟動
            if activationTimer == nil {
                activationTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                    self?.activate()
                }
            }
        }
    }

    /// 停止全域快捷鍵監聽
    func deactivate() {
        activationTimer?.invalidate()
        activationTimer = nil
        hotkeyManager.stop()
    }

    // MARK: - 錄音流程

    func startRecording() {
        guard state != .recording && state != .processing else { return }

        // 檢查麥克風權限
        guard AudioRecorder.hasPermission else {
            Task {
                let granted = await AudioRecorder.requestPermission()
                if !granted {
                    state = .error("需要麥克風使用權限")
                }
            }
            return
        }

        // 檢查 API Key
        guard settingsStore.apiKey() != nil else {
            state = .error("請先設定 API Key")
            return
        }

        do {
            try audioRecorder.startRecording()
            state = .recording

            // 播放開始音效
            if settingsStore.settings.playSoundEffects {
                NSSound(named: .init("Tink"))?.play()
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopRecordingAndTranscribe() {
        guard state == .recording else { return }

        guard let audioData = audioRecorder.stopRecording() else {
            state = .idle
            return
        }

        // 播放結束音效
        if settingsStore.settings.playSoundEffects {
            NSSound(named: .init("Pop"))?.play()
        }

        // 如果錄音太短（小於 0.3 秒），忽略
        if audioRecorder.recordingDuration < 0.3 {
            state = .idle
            return
        }

        state = .processing

        Task {
            await transcribeAndInject(audioData: audioData)
        }
    }

    // MARK: - 辨識與注入

    private func transcribeAndInject(audioData: Data) async {
        do {
            // 1. 呼叫 API 辨識
            let service = STTServiceFactory.create(for: .groq)
            let settings = settingsStore.settings

            var result = try await service.transcribe(
                audioData: audioData,
                language: settings.primaryLanguage.whisperCode,
                prompt: settings.whisperPrompt
            )

            print("[TypeGood] Whisper 原始結果: \(result.rawText)")

            // 2. LLM 語意後處理（使用獨立的 LLM 供應商）
            let llmProvider = settings.llmProvider
            if settings.enableLLMPostProcessing,
               let llmApiKey = settingsStore.apiKey(for: llmProvider) {
                print("[TypeGood] LLM 後處理啟用，使用 \(llmProvider.displayName) / \(llmProvider.llmModelName)")
                let llm = LLMPostProcessor(
                    provider: llmProvider,
                    apiKey: llmApiKey,
                    systemPrompt: settings.llmSystemPrompt
                )
                do {
                    result.processedText = try await llm.process(result.rawText)
                    print("[TypeGood] LLM 修正結果: \(result.processedText)")
                } catch {
                    print("[TypeGood] LLM 後處理失敗: \(error)")
                }
            } else {
                print("[TypeGood] LLM 後處理未啟用")
            }

            // 3. 規則式後處理（中英間距、標點轉換、詞彙替換）
            let processor = TextPostProcessor(settings: settings)
            result.processedText = processor.process(result.processedText)
            print("[TypeGood] 最終輸出: \(result.processedText)")

            // 4. 注入文字
            if !result.processedText.isEmpty {
                await TextInjector.inject(result.processedText)
            }

            lastResult = result
            state = .completed(result.processedText)

            // 4. 自動回到閒置狀態
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if case .completed = state {
                state = .idle
            }
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription

            // 自動清除錯誤狀態
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if case .error = state {
                state = .idle
                errorMessage = nil
            }
        }
    }
}
