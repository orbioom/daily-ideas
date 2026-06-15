import SwiftUI

/// A named set of chapter colors. Free users get the "Classic" set; Pro unlocks the rest.
/// Palettes drive (a) the color suggestions when creating chapters/milestones/goals and
/// (b) the optional "recolor everything" action. Stored values are hex strings on each model,
/// so a palette is purely a curated list of nice hexes.
struct Palette: Identifiable, Hashable {
    let id: String
    let name: String
    let isPro: Bool
    /// 6+ pleasant hex strings (without leading #).
    let hexes: [String]

    func color(_ index: Int) -> Color {
        guard !hexes.isEmpty else { return Theme.accent }
        let h = hexes[((index % hexes.count) + hexes.count) % hexes.count]
        return Color(hexString: h, fallback: Theme.accent)
    }

    var count: Int { hexes.count }
}

enum Palettes {
    static let classic = Palette(
        id: "classic",
        name: "Classic",
        isPro: false,
        hexes: ["E8A84B", "6FA8DC", "8FBF7F", "C98BB9", "E0746B", "7E8AA2"]
    )

    static let dusk = Palette(
        id: "dusk",
        name: "Dusk",
        isPro: true,
        hexes: ["F0A868", "C77DFF", "7B91D6", "5FB0B7", "E06C9F", "9A8C98"]
    )

    static let garden = Palette(
        id: "garden",
        name: "Garden",
        isPro: true,
        hexes: ["A7C957", "6A994E", "E9C46A", "F4A261", "E76F51", "8AB17D"]
    )

    static let tide = Palette(
        id: "tide",
        name: "Tide",
        isPro: true,
        hexes: ["48CAE4", "0096C7", "5390D9", "56CFE1", "64DFDF", "80FFDB"]
    )

    static let all: [Palette] = [classic, dusk, garden, tide]

    static func palette(id: String) -> Palette {
        all.first { $0.id == id } ?? classic
    }

    /// Resolve a palette honoring Pro gating: a locked Pro palette falls back to Classic.
    static func resolved(id: String, isPro: Bool) -> Palette {
        let p = palette(id: id)
        return (p.isPro && !isPro) ? classic : p
    }
}

/// How week dots are drawn in the grid. A persisted, functional preference.
enum DotStyle: String, CaseIterable, Identifiable {
    case round
    case square
    case soft        // small rounded-rect

    var id: String { rawValue }

    var label: String {
        switch self {
        case .round: return "Round"
        case .square: return "Square"
        case .soft: return "Soft"
        }
    }

    /// Corner radius for a dot of the given size; round uses size/2.
    func cornerRadius(for size: CGFloat) -> CGFloat {
        switch self {
        case .round: return size / 2
        case .square: return 0
        case .soft: return max(size * 0.28, 1)
        }
    }
}
