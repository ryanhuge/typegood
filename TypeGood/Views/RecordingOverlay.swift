import SwiftUI
import AppKit

/// 錄音狀態浮動指示器（顯示在螢幕角落）
final class RecordingOverlayController {
    static let shared = RecordingOverlayController()

    private var overlayWindow: NSWindow?
    private var hostingView: NSHostingView<RecordingOverlayView>?

    private init() {}

    func show() {
        guard overlayWindow == nil else { return }

        let view = RecordingOverlayView()
        let hosting = NSHostingView(rootView: view)
        hostingView = hosting

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 44),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = true

        // 置於螢幕右上角
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 130
            let y = screenFrame.maxY - 54
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.orderFront(nil)
        overlayWindow = window
    }

    func hide() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        hostingView = nil
    }

    func update(state: TranscriptionState, level: Float) {
        if let hosting = hostingView {
            hosting.rootView = RecordingOverlayView(state: state, audioLevel: level)
        }
    }
}

/// 浮動指示器 SwiftUI 視圖
struct RecordingOverlayView: View {
    var state: TranscriptionState = .recording
    var audioLevel: Float = 0.0

    var body: some View {
        HStack(spacing: 8) {
            // 錄音圓點
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .shadow(color: dotColor.opacity(0.6), radius: 4)

            // 狀態文字
            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)

            // 音量指示（僅錄音時顯示）
            if state.isRecording {
                AudioLevelDots(level: audioLevel)
            }

            if state.isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(dotColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var dotColor: Color {
        switch state {
        case .recording: return .red
        case .processing: return .orange
        default: return .green
        }
    }

    private var statusText: String {
        switch state {
        case .recording: return "錄音中"
        case .processing: return "辨識中"
        default: return ""
        }
    }
}

/// 音量指示圓點
struct AudioLevelDots: View {
    var level: Float

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Circle()
                    .fill(level > Float(i) / 5.0 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
}
