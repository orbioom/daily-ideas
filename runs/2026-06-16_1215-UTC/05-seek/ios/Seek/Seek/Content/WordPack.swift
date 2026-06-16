import SwiftUI

/// A themed collection of words used to build puzzles.
struct WordPack: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let tint: UInt
    /// Packs beyond the first three require Pro.
    let isPro: Bool
    let words: [String]

    var color: Color { Color(hex: tint) }
}
