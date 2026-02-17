# Changelog

所有版本更動紀錄。格式依照 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)。

## [1.0.0] - 2025-02-17

### 新增
- 核心語音輸入功能：按住右側 ⌘ 說話，放開自動辨識並輸入
- Groq Whisper API 語音辨識（whisper-large-v3-turbo）
- OpenAI GPT 語意修正（gpt-4o-mini），將口語整理為書面語
- CGEvent 鍵盤事件模擬，支援系統級文字輸入
- MenuBar 常駐圖示，顯示辨識狀態與結果
- 偏好設定視窗（一般、API、語言、詞彙庫）
- API Key 管理與連線測試
- 應用內 API Key 取得說明與連結
- 多語言辨識支援（繁中、簡中、英文、日文、韓文）
- 中英文混合辨識模式
- 標點符號風格切換（全形／半形／保持原樣）
- 中英文自動加空格
- 自訂 Whisper 提示詞
- 自訂 LLM 系統提示詞
- 詞彙替換庫（JSON 匯入／匯出）
- 預設 12 組常見辨識錯誤修正規則
- 各設定頁面的操作說明文字
- 自簽程式碼簽署（Hardened Runtime + 麥克風 Entitlement）

### 修正
- LLM 系統提示詞改為明確的「文字整理」指令，避免 LLM 誤將語音內容當作指令執行
- 新增設定遷移機制（v1→v2），升級後自動套用新版提示詞
- 修正 LSUIElement 應用程式無法顯示麥克風權限對話框的問題（切換 activationPolicy）
- 修正 Hardened Runtime 缺少 audio-input entitlement 導致權限按鈕無效
