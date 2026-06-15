import Foundation

/// A single slot in a layout. Coordinates use **half-step units**: a tile
/// occupies a 2×2 footprint in these units (width 2, height 2). This lets the
/// classic "Turtle" layout overlap tiles by half a tile in x or y.
///
/// `x` is the left edge column (in half-steps), `y` is the top edge row,
/// `layer` is the stacking height (0 = table level). A tile's footprint covers
/// columns `x...x+1` and rows `y...y+1` on its layer.
struct LayoutSlot: Codable, Hashable {
    var x: Int
    var y: Int
    var layer: Int
}

/// The available board layouts. Raw values used as persistence keys.
enum LayoutKind: String, Codable, CaseIterable, Identifiable {
    case turtle
    case pyramid
    case fortress
    case garden

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .turtle: return "Classic Turtle"
        case .pyramid: return "Pyramid"
        case .fortress: return "Fortress"
        case .garden: return "Garden"
        }
    }

    var subtitle: String {
        switch self {
        case .turtle: return "The timeless 144-tile shell"
        case .pyramid: return "A stacked four-sided climb"
        case .fortress: return "Walled keep with a high tower"
        case .garden: return "A gentle, smaller board"
        }
    }

    /// Whether this layout is available on the free tier.
    var isFreeTier: Bool {
        switch self {
        case .turtle, .garden: return true
        case .pyramid, .fortress: return false
        }
    }

    /// The slot list for this layout. Always an even count.
    var slots: [LayoutSlot] {
        switch self {
        case .turtle: return LayoutBuilder.turtle()
        case .pyramid: return LayoutBuilder.pyramid()
        case .fortress: return LayoutBuilder.fortress()
        case .garden: return LayoutBuilder.garden()
        }
    }

    var tileCount: Int { slots.count }
}

/// Programmatic slot generators. Each is documented and produces an even number
/// of slots. Coordinates are in half-steps (tile footprint = 2×2).
enum LayoutBuilder {

    /// Add a rectangular block of tiles on `layer`. `cols`×`rows` tiles, with the
    /// top-left tile's top-left corner at half-step (originX, originY). Tiles are
    /// placed on a 2-half-step grid (i.e. edge-to-edge, no overlap within a block).
    private static func block(_ slots: inout [LayoutSlot],
                              cols: Int, rows: Int,
                              originX: Int, originY: Int,
                              layer: Int) {
        guard cols > 0, rows > 0 else { return }
        for r in 0..<rows {
            for c in 0..<cols {
                slots.append(LayoutSlot(x: originX + c * 2, y: originY + r * 2, layer: layer))
            }
        }
    }

    // MARK: Classic Turtle (144 slots)

    /// The classic "turtle"/"shell" layout: a wide 8-row base with side flaps,
    /// progressively smaller centered layers, a single bridge tile on the right,
    /// and a capstone. Total = 144 slots (matches the full tile set).
    static func turtle() -> [LayoutSlot] {
        var s: [LayoutSlot] = []

        // Layer 0 — the body. Classic turtle base row widths per row (12 rows).
        // Row widths (in tiles): 12,8,10,12,12,10,8,12  → but we use the canonical
        // shape that totals to the well-known base. We build it row-by-row centered.
        // Canonical base (87 tiles) row tile-counts and their horizontal offsets:
        let base: [(count: Int, offsetCols: Int)] = [
            (12, 0),   // row 0
            (8, 2),    // row 1
            (10, 1),   // row 2
            (12, 0),   // row 3
            (12, 0),   // row 4
            (10, 1),   // row 5
            (8, 2),    // row 6
            (12, 0),   // row 7
        ]
        for (rowIndex, row) in base.enumerated() {
            block(&s, cols: row.count, rows: 1,
                  originX: 2 + row.offsetCols * 2,
                  originY: 2 + rowIndex * 2,
                  layer: 0)
        }

        // Layer 1 — 6×6 centered block (36 tiles).
        block(&s, cols: 6, rows: 6, originX: 6, originY: 4, layer: 1)

        // Layer 2 — 4×4 centered block (16 tiles).
        block(&s, cols: 4, rows: 4, originX: 8, originY: 6, layer: 2)

        // Layer 3 — 2×2 centered block (4 tiles).
        block(&s, cols: 2, rows: 2, originX: 10, originY: 8, layer: 3)

        // Layer 4 — capstone (1 tile).
        s.append(LayoutSlot(x: 11, y: 9, layer: 4))

        // The right "bridge"/tail tile on layer 0 sticking out to the side, and
        // a left "head" tile — classic turtle features. These also serve to make
        // the count even/144.
        // Currently: base = 84, L1 = 36, L2 = 16, L3 = 4, cap = 1 → 141.
        // Add 3 extension tiles on the right tail at layer 0 and adjust to 144.
        s.append(LayoutSlot(x: 28, y: 8, layer: 0))   // tail 1
        s.append(LayoutSlot(x: 30, y: 8, layer: 0))   // tail 2 (the protruding bridge)
        // head tile on the far left at layer 0
        s.append(LayoutSlot(x: 0, y: 8, layer: 0))    // head

        return dedupedEven(s, fallbackTarget: 144)
    }

    // MARK: Pyramid (even count)

    /// A centered four-sided step pyramid: square layers shrinking by one tile
    /// per side each level. Base 8×8 = 64, then 6×6, 4×4, 2×2, cap.
    static func pyramid() -> [LayoutSlot] {
        var s: [LayoutSlot] = []
        // layer sizes: 8,6,4,2 then a 1 cap → 64+36+16+4+1 = 121 (odd) → drop cap.
        let sizes = [8, 6, 4, 2]
        for (i, n) in sizes.enumerated() {
            let origin = 2 + i * 2   // each layer centered, inset by one tile per side
            block(&s, cols: n, rows: n, originX: origin, originY: origin, layer: i)
        }
        return dedupedEven(s, fallbackTarget: nil)
    }

    // MARK: Fortress (even count)

    /// A walled keep: a hollow square wall on layer 0 with solid corners,
    /// a smaller solid block on layer 1, and a tower of small blocks above.
    static func fortress() -> [LayoutSlot] {
        var s: [LayoutSlot] = []

        // Layer 0 — solid 10×8 courtyard floor (80 tiles).
        block(&s, cols: 10, rows: 8, originX: 2, originY: 2, layer: 0)

        // Layer 1 — a hollow square wall around the keep. Outer 8×6, inner hole 4×2.
        // Build outer ring by adding the full 8×6 then removing the inner block.
        var ring: [LayoutSlot] = []
        block(&ring, cols: 8, rows: 6, originX: 4, originY: 4, layer: 1)
        let inner = Set<LayoutSlot>({ () -> [LayoutSlot] in
            var h: [LayoutSlot] = []
            block(&h, cols: 4, rows: 2, originX: 8, originY: 8, layer: 1)
            return h
        }())
        s.append(contentsOf: ring.filter { !inner.contains($0) })

        // Layer 2 — the keep: 4×4 block (16 tiles).
        block(&s, cols: 4, rows: 4, originX: 8, originY: 6, layer: 2)

        // Layer 3 — tower: 2×2 (4 tiles).
        block(&s, cols: 2, rows: 2, originX: 10, originY: 8, layer: 3)

        return dedupedEven(s, fallbackTarget: nil)
    }

    // MARK: Garden (smaller, even count)

    /// A gentle smaller board for quick games: a 9×4 base with a 7×2 second
    /// layer and a 5×1 ridge. Designed to be easy to read and fast to clear.
    static func garden() -> [LayoutSlot] {
        var s: [LayoutSlot] = []
        block(&s, cols: 10, rows: 4, originX: 2, originY: 2, layer: 0)   // 40
        block(&s, cols: 8, rows: 2, originX: 4, originY: 4, layer: 1)    // 16
        block(&s, cols: 4, rows: 1, originX: 8, originY: 6, layer: 2)    // 4
        return dedupedEven(s, fallbackTarget: nil)   // 60
    }

    // MARK: Helpers

    /// Removes any duplicate slot positions and, if the count is odd, drops the
    /// last slot to keep the count even. If `fallbackTarget` is set and the count
    /// exceeds it, trims to that even target; if short, this is acceptable as long
    /// as the result is even (the dealer deals to whatever slot count exists).
    private static func dedupedEven(_ slots: [LayoutSlot], fallbackTarget: Int?) -> [LayoutSlot] {
        var seen = Set<LayoutSlot>()
        var out: [LayoutSlot] = []
        for slot in slots where !seen.contains(slot) {
            seen.insert(slot)
            out.append(slot)
        }
        if let target = fallbackTarget, out.count > target {
            out = Array(out.prefix(target))
        }
        if out.count % 2 != 0 { out.removeLast() }
        return out
    }
}
