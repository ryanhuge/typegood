import Foundation
import AVFoundation
import AppKit

/// 錄音引擎：使用 AVFoundation 錄製音訊
@Observable
final class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?

    var isRecording = false
    var currentLevel: Float = 0.0  // 0.0 ~ 1.0，用於音量顯示
    var recordingDuration: TimeInterval = 0

    private var recordingURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("typegood_recording.wav")
    }

    /// 開始錄音
    func startRecording() throws {
        // 確保上次錄音已停止
        stopRecording()

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,          // Whisper 最佳取樣率
            AVNumberOfChannelsKey: 1,           // 單聲道
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.delegate = self

        guard audioRecorder?.record() == true else {
            throw RecorderError.failedToStart
        }

        isRecording = true
        recordingDuration = 0

        // 啟動音量監測計時器
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateMeters()
        }
    }

    /// 停止錄音並回傳音訊資料
    @discardableResult
    func stopRecording() -> Data? {
        levelTimer?.invalidate()
        levelTimer = nil

        guard let recorder = audioRecorder, recorder.isRecording else {
            isRecording = false
            currentLevel = 0
            return nil
        }

        recordingDuration = recorder.currentTime
        recorder.stop()
        isRecording = false
        currentLevel = 0

        // 讀取錄音檔案
        defer { cleanupRecording() }
        return try? Data(contentsOf: recordingURL)
    }

    private func updateMeters() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        // 將 dB 值 (-160 ~ 0) 轉換為 0 ~ 1 的線性值
        let normalizedPower = max(0, min(1, (power + 50) / 50))
        currentLevel = normalizedPower
        recordingDuration = recorder.currentTime
    }

    private func cleanupRecording() {
        try? FileManager.default.removeItem(at: recordingURL)
        audioRecorder = nil
    }

    /// 請求麥克風權限（LSUIElement app 需暫時切換為一般 app 才能正常顯示對話框）
    @MainActor
    static func requestPermission() async -> Bool {
        let currentPermission = AVAudioApplication.shared.recordPermission

        // 已授權或已拒絕就不需要彈窗
        if currentPermission == .granted { return true }
        if currentPermission == .denied {
            openMicrophoneSettings()
            return false
        }

        // 暫時切換為一般 app（顯示 Dock 圖示），讓權限對話框可正常運作
        NSApp.setActivationPolicy(.regular)
        try? await Task.sleep(for: .milliseconds(100))
        NSApp.activate(ignoringOtherApps: true)

        let granted = await AVAudioApplication.requestRecordPermission()

        // 切回 menu bar only 模式
        try? await Task.sleep(for: .milliseconds(300))
        NSApp.setActivationPolicy(.accessory)

        return granted
    }

    static var hasPermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    /// 開啟系統設定的麥克風權限頁面
    static func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            isRecording = false
            currentLevel = 0
        }
    }
}

enum RecorderError: LocalizedError {
    case failedToStart
    case noPermission

    var errorDescription: String? {
        switch self {
        case .failedToStart: return "無法啟動錄音"
        case .noPermission: return "沒有麥克風使用權限"
        }
    }
}
