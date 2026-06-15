import Foundation

/// A face on a Mahjong tile. The full standard set is 144 tiles:
/// three numbered suits (Bamboo, Characters, Circles) 1–9 ×4,
/// Winds (E/S/W/N) ×4, Dragons (Red/Green/White) ×4,
/// Flowers ×1 each, Seasons ×1 each.
///
/// `TileFace` describes the *printed* face. Matching:
/// - Numbered suits / winds / dragons match an identical face only.
/// - Any Flower matches any Flower.
/// - Any Season matches any Season.
enum TileFace: Codable, Hashable {
    case bamboo(Int)      // 1...9
    case characters(Int)  // 1...9
    case circles(Int)     // 1...9
    case wind(Wind)
    case dragon(Dragon)
    case flower(Flower)
    case season(Season)

    enum Wind: Int, Codable, CaseIterable { case east, south, west, north }
    enum Dragon: Int, Codable, CaseIterable { case red, green, white }
    enum Flower: Int, Codable, CaseIterable { case plum, orchid, bamboo, chrysanthemum }
    enum Season: Int, Codable, CaseIterable { case spring, summer, autumn, winter }

    /// True if `self` is a legal Mahjong match with `other`.
    func matches(_ other: TileFace) -> Bool {
        switch (self, other) {
        case let (.bamboo(a), .bamboo(b)): return a == b
        case let (.characters(a), .characters(b)): return a == b
        case let (.circles(a), .circles(b)): return a == b
        case let (.wind(a), .wind(b)): return a == b
        case let (.dragon(a), .dragon(b)): return a == b
        case (.flower, .flower): return true   // any flower matches any flower
        case (.season, .season): return true   // any season matches any season
        default: return false
        }
    }

    /// A stable key grouping faces that are interchangeable for matching.
    /// Tiles share a match group iff `matches` is true between them.
    var matchGroup: String {
        switch self {
        case .bamboo(let n): return "B\(n)"
        case .characters(let n): return "C\(n)"
        case .circles(let n): return "D\(n)"
        case .wind(let w): return "W\(w.rawValue)"
        case .dragon(let d): return "G\(d.rawValue)"
        case .flower: return "F"
        case .season: return "S"
        }
    }
}

/// One physical tile instance placed on the board. `id` is unique per instance.
struct Tile: Identifiable, Codable, Hashable {
    let id: Int            // unique instance id (0..<144)
    let face: TileFace

    func matches(_ other: Tile) -> Bool { face.matches(other.face) }
}

// MARK: - Full standard tile set

enum TileSet {
    /// Returns the 144 faces of a standard Mahjong solitaire set.
    static func standardFaces() -> [TileFace] {
        var faces: [TileFace] = []
        for n in 1...9 {
            for _ in 0..<4 { faces.append(.bamboo(n)) }
            for _ in 0..<4 { faces.append(.characters(n)) }
            for _ in 0..<4 { faces.append(.circles(n)) }
        }
        for w in TileFace.Wind.allCases { for _ in 0..<4 { faces.append(.wind(w)) } }
        for d in TileFace.Dragon.allCases { for _ in 0..<4 { faces.append(.dragon(d)) } }
        for f in TileFace.Flower.allCases { faces.append(.flower(f)) }
        for s in TileFace.Season.allCases { faces.append(.season(s)) }
        return faces   // exactly 9*3*4 + 16 + 12 + 4 + 4 = 144
    }
}
