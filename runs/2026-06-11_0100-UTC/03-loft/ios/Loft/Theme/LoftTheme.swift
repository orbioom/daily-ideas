import SwiftUI

enum LoftTheme {
    static let cardRadius: CGFloat = 16
    static let boardRadius: CGFloat = 20

    static func categoryColor(_ cat: BoardCategory) -> Color {
        Color(hex: cat.accentHex) ?? .blue
    }
}

extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6,
              let value = UInt64(str, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
