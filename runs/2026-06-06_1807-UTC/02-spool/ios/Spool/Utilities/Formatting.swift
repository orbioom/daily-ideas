import SwiftUI

/// Currency + color helpers shared across the app.
enum Money {
    /// Formats an amount with the user's chosen symbol; two decimals.
    static func string(_ amount: Double, symbol: String) -> String {
        let v = amount.isFinite ? amount : 0
        return symbol + String(format: "%.2f", v)
    }
}

extension Color {
    /// Build a Color from a 6-character "RRGGBB" string. Falls back to gray.
    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
        if cleaned.count == 6, let value = UInt32(cleaned, radix: 16) {
            self.init(hex: value)
        } else {
            self.init(hex: 0xBFC4CC)
        }
    }
}

/// A set of friendly preset colors for the spool color picker (name + hex).
enum FilamentColors {
    static let presets: [(name: String, hex: String)] = [
        ("Natural", "BFC4CC"), ("Black", "1C1C20"), ("White", "F2F3F6"),
        ("Galaxy Black", "2A2D3A"), ("Red", "C0392B"), ("Orange", "E07B39"),
        ("Yellow", "E6C84F"), ("Green", "4FB98C"), ("Sky Blue", "5AA9E6"),
        ("Navy", "2C3E66"), ("Purple", "7D5BA6"), ("Pink", "D98FB0"),
        ("Silver", "A8AEB8"), ("Gold", "C9A24B"), ("Brown", "7A5230")
    ]
}
