import SwiftUI

enum SparkTheme {
    static let electricBlue = Color(red: 0.06, green: 0.53, blue: 0.98)
    static let deepBlue = Color(red: 0.04, green: 0.15, blue: 0.35)
    static let focusGreen = Color(red: 0.10, green: 0.82, blue: 0.42)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.08)
    static let softWhite = Color(red: 0.96, green: 0.97, blue: 1.00)

    static func categoryColor(_ cat: TaskCategory) -> Color {
        switch cat {
        case .work: return .blue
        case .study: return .purple
        case .creative: return .orange
        case .personal: return .green
        case .health: return .red
        case .chores: return .brown
        case .other: return .gray
        }
    }
}
