import SwiftUI

/// 設定視窗主框架
struct SettingsWindow: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("一般", systemImage: "gearshape")
                }

            APISettingsTab()
                .tabItem {
                    Label("API 設定", systemImage: "key")
                }

            LanguageSettingsTab()
                .tabItem {
                    Label("語言", systemImage: "globe")
                }

            VocabularyTab()
                .tabItem {
                    Label("詞彙庫", systemImage: "text.book.closed")
                }
        }
        .frame(width: 550, height: 450)
    }
}
