import Foundation

/// A static, hand-authored level definition (not persisted — content, not state).
struct Level: Identifiable, Equatable {
    /// Stable identifier, e.g. "garden-01". Used to seed the packer and key progress.
    let id: String
    let title: String
    /// The letters available to the player, e.g. "GARDEN".
    let baseWord: String
    /// All grid-eligible words formable from the base letters.
    let targetWords: [String]
    /// Curated extra words that count as bonus but never go on the grid.
    let extraBonusWords: [String]

    var letterMultiset: LetterMultiset { LetterMultiset(baseWord) }
}

/// A themed group of levels.
struct LevelPack: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    /// SF Symbol used as the pack glyph.
    let symbol: String
    let levels: [Level]
    /// When true, the whole pack requires Pro.
    let requiresPro: Bool
}
