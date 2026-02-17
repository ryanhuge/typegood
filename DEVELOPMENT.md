# 開發指南

本文件說明 TypeGood 的程式架構、模組職責、資料流程，以及新增功能的開發方式。

## 目錄結構

```
TypeGood/
├── TypeGoodApp.swift          # SwiftUI App 進入點
├── AppDelegate.swift          # AppKit 生命週期、權限請求、視窗管理
├── Core/                      # 核心業務邏輯
│   ├── AudioRecorder.swift        # 麥克風錄音（AVFoundation）
│   ├── HotkeyManager.swift        # 全域快捷鍵監聽（CGEvent Tap）
│   ├── TextInjector.swift         # 系統級文字注入（CGEvent 鍵盤模擬）
│   └── TranscriptionPipeline.swift # 語音辨識主流程管線
├── Models/                    # 資料模型
│   ├── APIProvider.swift          # API 供應商定義（Groq、OpenAI）
│   ├── AppSettings.swift          # 應用設定結構（Codable）
│   ├── CustomVocabulary.swift     # 詞彙替換規則
│   └── TranscriptionResult.swift  # 辨識結果
├── Services/                  # 外部 API 服務
│   ├── STTService.swift           # STT 服務協定 + 工廠
│   ├── GroqWhisperService.swift   # Groq Whisper API 實作
│   ├── OpenAIWhisperService.swift # OpenAI Whisper API 實作
│   ├── LLMPostProcessor.swift     # LLM 語意修正
│   └── TextPostProcessor.swift    # 本地文字後處理（空格、標點、詞彙替換）
├── Storage/                   # 資料持久化
│   ├── SettingsStore.swift        # 設定存取（UserDefaults）+ 遷移
│   ├── KeychainHelper.swift       # API Key 安全儲存
│   └── VocabularyStore.swift      # 詞彙庫檔案管理
├── Views/                     # SwiftUI 介面
│   ├── MenuBarView.swift          # MenuBar 彈出面板
│   ├── RecordingOverlay.swift     # 錄音中浮動提示
│   ├── SettingsWindow.swift       # 設定視窗（TabView）
│   ├── GeneralSettingsTab.swift   # 一般設定（權限、快捷鍵）
│   ├── APISettingsTab.swift       # API Key 管理
│   ├── LanguageSettingsTab.swift  # 語言與處理設定
│   └── VocabularyTab.swift        # 詞彙庫管理
└── Resources/
    ├── Info.plist                 # 應用程式資訊
    ├── TypeGood.entitlements      # 權限宣告
    ├── default_vocabulary.json    # 預設詞彙庫
    └── Assets.xcassets/           # App 圖示
```

## 核心資料流

```
使用者按住右 ⌘
       │
       ▼
  HotkeyManager（CGEvent Tap 攔截 keyCode 54）
       │
       ▼
  AudioRecorder.startRecording()
  （AVAudioEngine → 16kHz 16-bit mono WAV buffer）
       │
  使用者放開右 ⌘
       │
       ▼
  AudioRecorder.stopRecording() → WAV Data
       │
       ▼
  TranscriptionPipeline.process()
       │
       ├─ 1. GroqWhisperService.transcribe()
       │     POST multipart/form-data → api.groq.com
       │     回傳原始辨識文字
       │
       ├─ 2. TextPostProcessor.process()
       │     本地處理：詞彙替換、中英文加空格、標點轉換
       │
       ├─ 3. LLMPostProcessor.process()（若啟用）
       │     POST JSON → api.openai.com
       │     LLM 將口語整理為書面語
       │
       └─ 4. TextInjector.inject()
             CGEvent 模擬鍵盤輸入 → 系統級貼上文字
```

## 模組詳細說明

### HotkeyManager

- 使用 `CGEvent.tapCreate` 建立全域事件監聽
- 監聽 `.flagsChanged` 事件，偵測右側 ⌘ 鍵（keyCode 54）
- 按下時觸發 `onHotkeyDown`，放開時觸發 `onHotkeyUp`
- 需要「輔助使用」權限才能運作

### AudioRecorder

- 使用 `AVAudioEngine` 進行即時錄音
- 輸出格式：16kHz、16-bit、單聲道 WAV
- 提供即時音量 (`currentLevel`) 供 UI 顯示
- 權限請求使用 `AVAudioApplication.requestRecordPermission()`（macOS 14+）
- LSUIElement 應用需臨時切換 `activationPolicy` 才能顯示權限對話框

### TranscriptionPipeline

- 單例模式 (`shared`)，管理整體辨識流程
- 使用 `@Observable` 提供狀態更新給 SwiftUI
- 狀態機：`idle` → `recording` → `processing` → `completed` / `error`
- STT 固定使用 Groq Whisper，LLM 固定使用 OpenAI

### TextInjector

- 使用 `CGEvent` 模擬鍵盤事件
- 將文字寫入剪貼簿後，模擬 ⌘V 貼上
- 貼上後恢復原始剪貼簿內容

### SettingsStore

- 單例模式，使用 `@Observable` 驅動 UI 更新
- 設定以 JSON 編碼存入 UserDefaults
- `didSet` 觀察器自動儲存變更
- 內建版本遷移機制（`settingsVersion`），支援跨版本自動更新設定

### STTService 協定

```swift
protocol STTService {
    func transcribe(audioData: Data, language: String, prompt: String?) async throws -> STTResult
}
```

- `GroqWhisperService`：實作 Groq API（主要使用）
- `OpenAIWhisperService`：實作 OpenAI Whisper API（備用）
- `STTServiceFactory.create(for:)` 工廠方法建立實例

## 設定遷移

在 `SettingsStore.migrateIfNeeded()` 中管理設定遷移：

```swift
private static let currentSettingsVersion = 2

// v1 → v2: 更新 LLM 系統提示詞
if storedVersion < 2 {
    // 偵測舊版預設提示詞並替換為新版
}
```

新增遷移步驟：
1. 將 `currentSettingsVersion` 加 1
2. 在 `migrateIfNeeded()` 中新增 `if storedVersion < N` 區塊
3. 遷移只會執行一次（版號記錄在 UserDefaults）

## 新增 API 供應商

1. 在 `APIProvider` enum 新增 case
2. 實作 `STTService` 或建立新的 LLM 服務
3. 在 `APISettingsTab` 新增對應的 Key 欄位
4. 更新 `TranscriptionPipeline` 的服務選擇邏輯

## 新增設定欄位

1. 在 `AppSettings` struct 新增屬性與預設值
2. 在 `init(from decoder:)` 使用 `decodeIfPresent` 並提供 fallback
3. 在對應的 Settings Tab 新增 UI 控件
4. 若需要遷移舊值，在 `SettingsStore.migrateIfNeeded()` 新增邏輯

## 程式碼風格

- 使用 Swift 5.10 語法
- SwiftUI 搭配 `@Observable`（非 ObservableObject）
- 單例使用 `static let shared`
- 非同步操作使用 Swift Concurrency（async/await）
- 檔案內註解使用繁體中文
- 程式碼中的字串常數使用繁體中文（面向台灣使用者）
