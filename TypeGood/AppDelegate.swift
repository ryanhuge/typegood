import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var settingsWindow: NSWindow?
    private let pipeline = TranscriptionPipeline.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupMenuBar()

        // 首次啟動時彈出輔助使用權限提示
        _ = HotkeyManager.shared.requestAccessibilityPermission()

        // 啟動快捷鍵（若權限未授權會自動定時重試）
        pipeline.activate()

        // 請求麥克風權限
        Task {
            _ = await AudioRecorder.requestPermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        pipeline.deactivate()
    }

    // MARK: - MenuBar 設定

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "TypeGood")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - 設定視窗

    func openSettings() {
        // 先關閉 popover
        popover.performClose(nil)

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsWindow()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "TypeGood 偏好設定"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    /// 更新 MenuBar 圖示狀態
    func updateStatusIcon(isRecording: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isRecording {
                self?.statusItem.button?.image = NSImage(systemSymbolName: "mic.badge.plus", accessibilityDescription: "錄音中")
            } else {
                self?.statusItem.button?.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "TypeGood")
            }
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == settingsWindow {
            settingsWindow = nil
        }
    }
}
