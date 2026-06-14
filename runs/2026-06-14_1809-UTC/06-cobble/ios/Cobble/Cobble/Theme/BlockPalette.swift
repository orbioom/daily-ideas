import SwiftUI

/// A cohesive set of block colors (not a rainbow circus). Color index 0 = empty.
/// Indices 1...count map into `colors`. Each `BlockPalette` provides a light+dark
/// resolving `Color` for every index plus a brighter top-highlight color.
struct BlockPalette: Identifiable, Equatable {
    let id: String
    let name: String
    let isPro: Bool
    /// Base fills for color indices 1...n (index 0 is empty, handled by the board).
    private let lights: [UInt]
    private let darks: [UInt]

    init(id: String, name: String, isPro: Bool, lights: [UInt], darks: [UInt]) {
        self.id = id
        self.name = name
        self.isPro = isPro
        self.lights = lights
        self.darks = darks
    }

    /// Number of distinct block colors (excluding empty).
    var count: Int { min(lights.count, darks.count) }

    /// Resolve the fill color for a 1-based color index. Returns clear for empty/out-of-range.
    func color(_ index: Int) -> Color {
        guard index >= 1, index <= count else { return .clear }
        return Color.dyn(lights[index - 1], darks[index - 1])
    }

    static func == (lhs: BlockPalette, rhs: BlockPalette) -> Bool { lhs.id == rhs.id }
}

enum BlockPalettes {
    /// The free default: a calm, cohesive six-color set anchored on the blue accent.
    static let classic = BlockPalette(
        id: "classic",
        name: "Cobble",
        isPro: false,
        lights: [0x4361E8, 0x2E9E6B, 0xE8954A, 0xD64577, 0x8A5BD6, 0x37A8C4],
        darks:  [0x6E86F2, 0x4FCB92, 0xF2A968, 0xEE6F9B, 0xA784E6, 0x55C4DD]
    )

    /// Pro: warm sunset set.
    static let sunset = BlockPalette(
        id: "sunset",
        name: "Sunset",
        isPro: true,
        lights: [0xE8654F, 0xE8954A, 0xE5C04A, 0xD64577, 0xB1466F, 0x7A4E8C],
        darks:  [0xF27E68, 0xF2A968, 0xF0D072, 0xEE6F9B, 0xC96D90, 0x9C6FAE]
    )

    /// Pro: cool forest set.
    static let forest = BlockPalette(
        id: "forest",
        name: "Forest",
        isPro: true,
        lights: [0x2E9E6B, 0x4C9A4A, 0x7BAE3C, 0x37A8C4, 0x2F7DB5, 0x6B8E6B],
        darks:  [0x4FCB92, 0x6CC069, 0x9BCD5E, 0x55C4DD, 0x5298CE, 0x8FAE8F]
    )

    /// Pro: candy / neon-pastel set.
    static let candy = BlockPalette(
        id: "candy",
        name: "Candy",
        isPro: true,
        lights: [0xEE6F9B, 0x8A5BD6, 0x4361E8, 0x37A8C4, 0x2E9E6B, 0xE8954A],
        darks:  [0xF490B5, 0xA784E6, 0x6E86F2, 0x55C4DD, 0x4FCB92, 0xF2A968]
    )

    static let all: [BlockPalette] = [classic, sunset, forest, candy]

    static func palette(id: String) -> BlockPalette {
        all.first { $0.id == id } ?? classic
    }
}
