import SwiftUI

struct KanaTheme {
    static let crimsonRed = Color(red: 0.80, green: 0.12, blue: 0.14)
    static let sakuraPink = Color(red: 1.0, green: 0.71, blue: 0.76)
    static let inkBlack = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let goldAccent = Color(red: 0.95, green: 0.78, blue: 0.24)
    static let katakanaBlue = Color(red: 0.18, green: 0.42, blue: 0.82)
    static let kanjiPurple = Color(red: 0.52, green: 0.18, blue: 0.72)

    static func cardTypeColor(_ type: CardType) -> Color {
        switch type {
        case .hiragana: return crimsonRed
        case .katakana: return katakanaBlue
        case .kanji: return kanjiPurple
        }
    }

    static func cardTypeIcon(_ type: CardType) -> String {
        switch type {
        case .hiragana: return "a.circle.fill"
        case .katakana: return "k.circle.fill"
        case .kanji: return "character.book.closed.fill"
        }
    }
}
