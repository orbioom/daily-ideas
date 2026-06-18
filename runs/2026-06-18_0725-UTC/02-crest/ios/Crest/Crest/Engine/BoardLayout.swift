import CoreGraphics

/// The three supported board geometries. All use the SAME adjacency rule for play;
/// they differ only in the tableau shape and its covering graph.
enum BoardLayout: String, Codable, CaseIterable, Identifiable {
    case threePeaks
    case pyramid
    case diamond

    var id: String { rawValue }

    var title: String {
        switch self {
        case .threePeaks: return "Three Peaks"
        case .pyramid: return "Pyramid"
        case .diamond: return "Diamond"
        }
    }

    var subtitle: String {
        switch self {
        case .threePeaks: return "The classic — three overlapping peaks."
        case .pyramid: return "One tall 28-card pyramid."
        case .diamond: return "A symmetric diamond variant."
        }
    }

    var isPro: Bool { self != .threePeaks }

    var symbolName: String {
        switch self {
        case .threePeaks: return "mountain.2.fill"
        case .pyramid: return "triangle.fill"
        case .diamond: return "diamond.fill"
        }
    }

    /// Every layout deals exactly 28 tableau cards (plus 23 stock + 1 initial waste = 24 remaining).
    var tableauCount: Int { spec.positions.count }

    var spec: BoardSpec { BoardLayoutFactory.spec(for: self) }
}

/// A single tableau slot: a normalized layout coordinate plus a depth (row) for shading.
struct BoardPosition: Identifiable, Equatable {
    let id: Int          // 0-based index into the tableau
    let x: CGFloat       // normalized 0...1 (column center)
    let y: CGFloat       // normalized 0...1 (row center, 0 = top)
    let row: Int         // 0 = top peak row; deeper rows are visually lower
}

/// Full description of a board geometry.
struct BoardSpec {
    let positions: [BoardPosition]
    /// `covers[i]` = the set of positions that sit directly on top of position `i`
    /// (i.e. `i` becomes playable only once all of these are cleared).
    let covers: [[Int]]
    /// Normalized board aspect (width / height) used to size the play area.
    let aspect: CGFloat

    var count: Int { positions.count }
}
