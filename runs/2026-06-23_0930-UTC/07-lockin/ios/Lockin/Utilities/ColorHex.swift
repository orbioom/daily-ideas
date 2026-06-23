import SwiftUI

extension Color {
    /// Create a color from a 6-digit hex string. Returns nil for malformed input.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

/// Curated, accessible swatches for projects.
enum ProjectPalette {
    static let hexes: [String] = [
        "7B51B8", "E08F3A", "3299A1", "C84A4F",
        "32A368", "4A6FE0", "B8519A", "5B6470"
    ]
    static let icons: [String] = [
        "target", "book.closed.fill", "laptopcomputer", "paintbrush.fill",
        "chart.bar.fill", "pencil.and.outline", "function", "leaf.fill",
        "briefcase.fill", "graduationcap.fill", "music.note", "hammer.fill"
    ]
}
