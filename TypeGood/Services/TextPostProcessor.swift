import Foundation

/// 文字後處理器：處理中英混合、標點轉換、詞彙替換
struct TextPostProcessor {

    let settings: AppSettings
    let vocabulary: VocabularyLibrary

    init(settings: AppSettings = SettingsStore.shared.settings,
         vocabulary: VocabularyLibrary = VocabularyStore.shared.library) {
        self.settings = settings
        self.vocabulary = vocabulary
    }

    /// 執行完整後處理流水線
    func process(_ text: String) -> String {
        var result = text

        // 1. 自訂詞彙替換
        result = applyVocabularyRules(result)

        // 2. 中英文間距處理
        if settings.autoSpaceBetweenCJKAndLatin {
            result = addSpacesBetweenCJKAndLatin(result)
        }

        // 3. 標點符號轉換
        result = convertPunctuation(result, style: settings.punctuationStyle)

        // 4. 清理多餘空白
        result = cleanupWhitespace(result)

        return result
    }

    // MARK: - 詞彙替換

    /// 套用自訂詞彙替換規則
    func applyVocabularyRules(_ text: String) -> String {
        var result = text
        for rule in vocabulary.activeRules {
            result = result.replacingOccurrences(of: rule.source, with: rule.target)
        }
        return result
    }

    // MARK: - 中英文間距

    /// 在中文與英文/數字之間加入空格
    func addSpacesBetweenCJKAndLatin(_ text: String) -> String {
        var result = ""
        let chars = Array(text)

        for i in 0..<chars.count {
            result.append(chars[i])

            if i + 1 < chars.count {
                let current = chars[i]
                let next = chars[i + 1]

                let currentIsCJK = isCJK(current)
                let nextIsCJK = isCJK(next)
                let currentIsLatinOrDigit = isLatinOrDigit(current)
                let nextIsLatinOrDigit = isLatinOrDigit(next)

                // CJK 後面接 Latin/數字，或 Latin/數字 後面接 CJK
                if (currentIsCJK && nextIsLatinOrDigit) || (currentIsLatinOrDigit && nextIsCJK) {
                    result.append(" ")
                }
            }
        }

        return result
    }

    private func isCJK(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        let value = scalar.value
        return (value >= 0x4E00 && value <= 0x9FFF) ||   // CJK Unified Ideographs
               (value >= 0x3400 && value <= 0x4DBF) ||   // CJK Extension A
               (value >= 0x3000 && value <= 0x303F) ||   // CJK Symbols and Punctuation
               (value >= 0xFF00 && value <= 0xFFEF) ||   // Fullwidth Forms
               (value >= 0x3040 && value <= 0x309F) ||   // Hiragana
               (value >= 0x30A0 && value <= 0x30FF) ||   // Katakana
               (value >= 0xAC00 && value <= 0xD7AF)      // Korean Hangul
    }

    private func isLatinOrDigit(_ char: Character) -> Bool {
        return char.isASCII && (char.isLetter || char.isNumber)
    }

    // MARK: - 標點轉換

    private static let halfToFull: [(String, String)] = [
        (",", "，"), (".", "。"), ("!", "！"), ("?", "？"),
        (":", "："), (";", "；"), ("(", "（"), (")", "）"),
    ]

    private static let fullToHalf: [(String, String)] = halfToFull.map { ($0.1, $0.0) }

    func convertPunctuation(_ text: String, style: PunctuationStyle) -> String {
        switch style {
        case .keep:
            return text
        case .fullWidth:
            return applyPunctuationMapping(text, mapping: Self.halfToFull)
        case .halfWidth:
            return applyPunctuationMapping(text, mapping: Self.fullToHalf)
        }
    }

    private func applyPunctuationMapping(_ text: String, mapping: [(String, String)]) -> String {
        var result = text
        for (from, to) in mapping {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }

    // MARK: - 清理

    /// 清理多餘的連續空白
    func cleanupWhitespace(_ text: String) -> String {
        var result = text
        // 移除連續多個空格
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        // 移除首尾空白
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }
}
