import Foundation
import AppKit

/// 文字注入器：將辨識結果透過剪貼簿 + Cmd+V 貼到目標應用
enum TextInjector {

    /// 將文字注入到當前焦點的輸入框
    static func inject(_ text: String) async {
        let pasteboard = NSPasteboard.general

        // 1. 備份當前剪貼簿內容
        let backup = backupPasteboard()

        // 2. 設定辨識結果到剪貼簿
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 3. 短暫延遲確保剪貼簿更新
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // 4. 模擬 Cmd+V 貼上
        simulatePaste()

        // 5. 延遲後還原剪貼簿
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        restorePasteboard(backup)
    }

    /// 模擬 Cmd+V 按鍵組合
    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 9 = 'V'
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    // MARK: - 剪貼簿備份與還原

    private struct PasteboardBackup {
        var items: [(type: NSPasteboard.PasteboardType, data: Data)]
    }

    private static func backupPasteboard() -> PasteboardBackup {
        let pasteboard = NSPasteboard.general
        var items: [(type: NSPasteboard.PasteboardType, data: Data)] = []

        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                items.append((type: type, data: data))
            }
        }

        return PasteboardBackup(items: items)
    }

    private static func restorePasteboard(_ backup: PasteboardBackup) {
        guard !backup.items.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        for item in backup.items {
            pasteboard.setData(item.data, forType: item.type)
        }
    }
}
