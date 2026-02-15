import SwiftUI
import ServiceManagement

/// 一般設定頁面
struct GeneralSettingsTab: View {
    private var settingsStore = SettingsStore.shared

    @State private var hotkeyDisplay: String = "右側 ⌘"
    @State private var accessibilityGranted: Bool = false
    @State private var micPermissionGranted: Bool = false
    @State private var permissionTimer: Timer?

    var body: some View {
        Form {
            Section("快捷鍵") {
                HStack {
                    Text("按住說話快捷鍵")
                    Spacer()
                    Text(hotkeyDisplay)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    // TODO: 未來可加入快捷鍵錄製功能
                }
            }

            Section("權限") {
                HStack {
                    Text("輔助使用權限")
                    Spacer()
                    if accessibilityGranted {
                        Label("已授權", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("前往設定") {
                            openAccessibilitySettings()
                        }
                    }
                }

                HStack {
                    Text("麥克風權限")
                    Spacer()
                    if micPermissionGranted {
                        Label("已授權", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("請求權限") {
                            Task {
                                micPermissionGranted = await AudioRecorder.requestPermission()
                            }
                        }
                        Button("前往設定") {
                            AudioRecorder.openMicrophoneSettings()
                        }
                    }
                }
            }
            .onAppear {
                checkPermissions()
                // 每 2 秒自動檢查一次權限狀態
                permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                    checkPermissions()
                }
            }
            .onDisappear {
                permissionTimer?.invalidate()
                permissionTimer = nil
            }

            Section("行為") {
                Toggle("播放音效提示", isOn: Bindable(settingsStore).settings.playSoundEffects)

                Toggle("開機自動啟動", isOn: Bindable(settingsStore).settings.launchAtLogin)
                    .onChange(of: settingsStore.settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("關於") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("TypeGood")
                    Spacer()
                    Text("語音輸入，好好打字")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        micPermissionGranted = AudioRecorder.hasPermission
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("設定開機啟動失敗: \(error)")
        }
    }
}
