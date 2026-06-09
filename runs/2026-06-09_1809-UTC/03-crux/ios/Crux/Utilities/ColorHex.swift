import SwiftUI

/// Resolves a 6-digit hex string (e.g. "4A7C8C") to a Color, falling back to the
/// Crux brand accent for malformed input. Used by Areas / Projects / Tags.
extension Color {
    init(brandHex string: String) {
        let cleaned = string.trimmingCharacters(in: CharacterSet(charactersIn: "# ")).uppercased()
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            self = Brand.magic
            return
        }
        self.init(hex: value)
    }
}

/// A curated palette of calm hexes for new areas/projects/tags.
enum CruxPalette {
    static let swatches: [String] = [
        "4A7C8C", "6A8E68", "B07C4E", "8C5A6E",
        "5E6B8C", "9A8C5E", "4E8C7C", "8C6A4E"
    ]

    /// Deterministic pick so repeated callers get a stable color.
    static func color(forIndex index: Int) -> String {
        guard !swatches.isEmpty else { return "4A7C8C" }
        return swatches[((index % swatches.count) + swatches.count) % swatches.count]
    }
}
