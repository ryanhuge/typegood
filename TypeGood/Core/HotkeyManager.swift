import Foundation
import Carbon
import Cocoa

/// 全域快捷鍵管理器（按住說話模式）
final class HotkeyManager {
    static let shared = HotkeyManager()

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isHotkeyPressed = false

    // 預設快捷鍵：右側 Command（keyCode 54）
    var targetKeyCode: UInt16 = 54  // Right Command

    private init() {}

    /// 啟動全域快捷鍵監聽
    func start() -> Bool {
        // 檢查輔助使用權限
        guard checkAccessibilityPermission() else {
            return false
        }

        // 監聽修飾鍵變化（右側 Command 屬於修飾鍵）
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    /// 停止全域快捷鍵監聽
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isHotkeyPressed = false
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // 如果事件 tap 被停用，重新啟用
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // 修飾鍵按下/放開透過 flagsChanged 偵測
        guard type == .flagsChanged else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))

        // 檢查是否為目標修飾鍵（右側 Command = 54）
        guard keyCode == targetKeyCode else {
            return Unmanaged.passRetained(event)
        }

        let flags = event.flags
        let isCommandPressed = flags.contains(.maskCommand)

        if isCommandPressed && !isHotkeyPressed {
            // 右側 Command 按下
            isHotkeyPressed = true
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown?()
            }
            return nil  // 吞掉事件
        } else if !isCommandPressed && isHotkeyPressed {
            // 右側 Command 放開
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onKeyUp?()
            }
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    /// 檢查輔助使用權限（不彈出提示）
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 檢查輔助使用權限並彈出系統提示
    func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 更新快捷鍵設定
    func updateHotkey(keyCode: UInt16) {
        let wasRunning = eventTap != nil
        if wasRunning { stop() }
        targetKeyCode = keyCode
        if wasRunning { _ = start() }
    }
}
