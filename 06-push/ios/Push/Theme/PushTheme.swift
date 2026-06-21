import SwiftUI

enum PushTheme {
    // MARK: - Background
    static let background = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let backgroundDark = Color(red: 0.10, green: 0.09, blue: 0.08)

    // MARK: - Grid cells
    static let wall = Color(red: 0.28, green: 0.25, blue: 0.22)
    static let floor = Color(red: 0.90, green: 0.88, blue: 0.84)
    static let floorDark = Color(red: 0.20, green: 0.18, blue: 0.16)
    static let target = Color(red: 0.60, green: 0.80, blue: 0.60)
    static let box = Color(red: 0.72, green: 0.50, blue: 0.28)
    static let boxOnTarget = Color(red: 0.28, green: 0.68, blue: 0.38)
    static let player = Color(red: 0.20, green: 0.45, blue: 0.85)

    // MARK: - Accent
    static let accent = Color(red: 0.90, green: 0.50, blue: 0.20)

    // MARK: - Pack colors
    static let pack1 = Color(red: 0.40, green: 0.70, blue: 0.90)  // sky blue
    static let pack2 = Color(red: 0.55, green: 0.78, blue: 0.45)  // green
    static let pack3 = Color(red: 0.90, green: 0.65, blue: 0.30)  // amber
    static let pack4 = Color(red: 0.80, green: 0.35, blue: 0.35)  // red
    static let pack5 = Color(red: 0.65, green: 0.45, blue: 0.85)  // purple

    static func packColor(_ packId: Int) -> Color {
        switch packId {
        case 1: return pack1
        case 2: return pack2
        case 3: return pack3
        case 4: return pack4
        case 5: return pack5
        default: return accent
        }
    }

    // MARK: - Typography helpers
    static let monoFont = Font.system(.body, design: .monospaced)
    static let titleFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let headlineFont = Font.system(.headline, design: .rounded, weight: .semibold)
    static let captionFont = Font.system(.caption, design: .rounded)
}
