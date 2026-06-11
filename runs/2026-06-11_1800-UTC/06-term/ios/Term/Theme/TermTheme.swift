import SwiftUI

enum TermTheme {
    static let accent   = Color("AccentIndigo")
    static let bg       = Color("BGPrimary")
    static let card     = Color("CardSurface")
    static let subtle   = Color("SubtleText")

    static let green    = Color.green
    static let orange   = Color.orange
    static let red      = Color.red
    static let blue     = Color.blue

    static func gradeColor(_ pct: Double) -> Color {
        switch pct {
        case 90...: return .green
        case 80..<90: return .blue
        case 70..<80: return .orange
        default: return .red
        }
    }

    static func gpaColor(_ gpa: Double) -> Color {
        switch gpa {
        case 3.5...: return .green
        case 3.0..<3.5: return .blue
        case 2.0..<3.0: return .orange
        default: return .red
        }
    }
}
