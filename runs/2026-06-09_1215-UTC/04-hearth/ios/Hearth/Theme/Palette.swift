import SwiftUI

/// Maps a `Room.colorIndex` to a Brand accent so rooms feel distinct while
/// staying inside the Orbioom palette in both light and dark.
enum Palette {
    static let accents: [Color] = [
        Brand.magic,
        Brand.info,
        Brand.live,
        Brand.warn,
        Brand.danger,
        Brand.text2
    ]

    static func color(_ index: Int) -> Color {
        guard !accents.isEmpty else { return Brand.magic }
        let i = ((index % accents.count) + accents.count) % accents.count
        return accents[i]
    }

    static let count = accents.count

    /// A curated set of room SF Symbols offered when adding/editing a room.
    static let roomSymbols: [String] = [
        "house", "fork.knife", "shower", "bed.double", "sofa", "door.left.hand.open",
        "desktopcomputer", "washer", "stairs", "car", "leaf", "books.vertical",
        "tv", "cabinet", "lightbulb", "sparkles"
    ]
}
