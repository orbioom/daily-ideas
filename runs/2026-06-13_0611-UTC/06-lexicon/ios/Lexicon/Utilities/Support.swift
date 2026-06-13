import SwiftUI
import UIKit

enum Haptics {
    static var enabled = true
    static func tap() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var scheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
}

extension LetterState {
    var emoji: String {
        switch self {
        case .correct: return "🟩"
        case .present: return "🟨"
        default: return "⬛️"
        }
    }
}

enum ShareCard {
    static func text(title: String, rows: [[LetterState]], won: Bool, attempts: Int) -> String {
        let head = "Lexicon \(title) \(won ? "\(attempts)" : "X")/\(WordGame.maxRows)"
        let grid = rows.map { $0.map(\.emoji).joined() }.joined(separator: "\n")
        return head + "\n" + grid
    }
}
