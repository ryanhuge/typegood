import SwiftUI

@main
struct TypeGoodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 設定視窗由 AppDelegate 程式化管理
        // 此處提供最小 Scene 作為 SwiftUI 生命週期錨點
        Settings {
            EmptyView()
        }
    }
}
