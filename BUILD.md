# 建置與打包指南

本文件說明如何從原始碼建置 TypeGood 並打包為 DMG 發行。

## 環境需求

| 項目 | 版本 |
|------|------|
| macOS | 14.0 Sonoma 以上 |
| Xcode | 16.0 以上 |
| Swift | 5.10 |
| XcodeGen | 2.38+ |
| 處理器 | Apple Silicon（M1 以上） |

## 安裝開發工具

```bash
# 安裝 XcodeGen（用於從 project.yml 產生 .xcodeproj）
brew install xcodegen
```

## 建置流程

### 1. 產生 Xcode 專案

```bash
xcodegen generate
```

此指令讀取 `project.yml`，產生 `TypeGood.xcodeproj`。每次修改 `project.yml` 後都需要重新執行。

### 2. 程式碼簽署

本專案使用自簽憑證 `TypeGood Developer` 進行 Hardened Runtime 簽署。新環境需建立此憑證：

```bash
# 產生私鑰與自簽憑證（有效期 10 年）
openssl req -x509 -newkey rsa:2048 -days 3650 \
  -subj "/CN=TypeGood Developer" \
  -keyout typegood.key -out typegood.crt -nodes \
  -addext "keyUsage=digitalSignature" \
  -addext "extendedKeyUsage=codeSigning"

# 匯出為 .p12（macOS Keychain 格式）
openssl pkcs12 -export -legacy \
  -inkey typegood.key -in typegood.crt \
  -out typegood.p12 -passout pass:

# 匯入 Keychain
security import typegood.p12 -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign

# 信任憑證
security add-trusted-cert -p codeSign -k ~/Library/Keychains/login.keychain-db typegood.crt

# 清理暫存檔
rm typegood.key typegood.crt typegood.p12
```

驗證憑證是否可用：

```bash
security find-identity -v -p codesigning
# 應看到「TypeGood Developer」
```

### 3. 命令列建置

```bash
# Release 建置
xcodebuild build \
  -project TypeGood.xcodeproj \
  -scheme TypeGood \
  -configuration Release \
  -derivedDataPath build

# 建置產物位於：
# build/Build/Products/Release/TypeGood.app
```

### 4. 使用 Xcode 建置

```bash
open TypeGood.xcodeproj
```

在 Xcode 中選擇 `TypeGood` scheme → Product → Build（⌘B）。

## 打包 DMG

```bash
hdiutil create \
  -volname "TypeGood" \
  -srcfolder build/Build/Products/Release/TypeGood.app \
  -ov -format UDZO \
  ~/Desktop/TypeGood.dmg
```

## 專案設定說明

### project.yml 關鍵設定

| 設定 | 值 | 說明 |
|------|-----|------|
| `MACOSX_DEPLOYMENT_TARGET` | 14.0 | 最低支援 macOS 版本 |
| `SWIFT_VERSION` | 5.10 | Swift 語言版本 |
| `ENABLE_HARDENED_RUNTIME` | true | 啟用 Hardened Runtime（macOS 安全要求） |
| `CODE_SIGN_IDENTITY` | TypeGood Developer | 程式碼簽署身份 |
| `ENABLE_APP_SANDBOX` | false | 關閉沙盒（需要系統級鍵盤事件存取） |
| `LSUIElement` | true | MenuBar 應用（不顯示 Dock 圖示） |

### Entitlements

`TypeGood/Resources/TypeGood.entitlements` 包含：

- `com.apple.security.device.audio-input` — 麥克風存取權限

### Info.plist 重點

- `LSUIElement: true` — 純 MenuBar 應用
- `NSMicrophoneUsageDescription` — 麥克風權限說明文字
- `CFBundleDevelopmentRegion: zh-Hant` — 預設語系繁體中文

## 資料儲存位置

| 資料 | 位置 | 說明 |
|------|------|------|
| 應用程式設定 | UserDefaults (`com.typegood.settings`) | JSON 編碼存入 UserDefaults |
| API Key | `~/Library/Application Support/TypeGood/apikeys.json` | 檔案權限 0600 |
| 詞彙庫 | `~/Library/Application Support/TypeGood/vocabulary.json` | JSON 格式 |
| 設定版本 | UserDefaults (`com.typegood.settingsVersion`) | 遷移版號控制 |

## 清除建置

```bash
rm -rf build/
xcodegen generate  # 重新產生 .xcodeproj
```

## 常見問題

### 簽署失敗：No signing identity found

確認已建立並信任 `TypeGood Developer` 憑證（見上方步驟 2）。

### XcodeGen 覆蓋了 .entitlements

Entitlements 由 `project.yml` 的 `entitlements.properties` 控制，不要直接編輯 `.entitlements` 檔案。

### 麥克風權限對話框不出現

確認：
1. Entitlements 包含 `com.apple.security.device.audio-input`
2. 使用具名簽署身份（非 ad-hoc `-`）
3. 重新安裝 App 後，在系統設定中手動授權
