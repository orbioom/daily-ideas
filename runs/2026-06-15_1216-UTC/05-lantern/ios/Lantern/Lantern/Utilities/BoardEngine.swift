import Foundation

/// A placed tile: a face occupying a specific slot index, plus removed state.
struct PlacedTile: Codable, Hashable, Identifiable {
    let id: Int           // unique instance id
    let face: TileFace
    let slotIndex: Int    // index into the layout's `slots`
    var removed: Bool

    var tile: Tile { Tile(id: id, face: face) }
}

/// The pure, value-type game board. Holds the layout's slots and the placed
/// tiles, and computes free-tile state and legal matches. No UI, no SwiftUI.
///
/// ## Free-tile rule
/// A tile is **free** iff:
///  (a) no *not-removed* tile on a strictly higher layer overlaps its 2×2
///      footprint, AND
///  (b) at least one of its immediate left or right neighbor positions on the
///      same layer is empty (no not-removed tile overlapping that side).
///
/// Footprints are 2×2 in half-step units, so two slots on the same layer overlap
/// iff their x-ranges and y-ranges both intersect. A higher tile "covers" a lower
/// one iff their footprints overlap on the x/y plane regardless of layer.
struct Board: Codable, Hashable {
    let layout: LayoutKind
    let slots: [LayoutSlot]
    var tiles: [PlacedTile]      // one per slot (same count), some removed

    // Fast lookup: instance id -> index in `tiles`.
    private var indexByID: [Int: Int] {
        var m: [Int: Int] = [:]
        for (i, t) in tiles.enumerated() { m[t.id] = i }
        return m
    }

    var remainingCount: Int { tiles.lazy.filter { !$0.removed }.count }
    var isCleared: Bool { remainingCount == 0 }

    // MARK: Geometry

    /// Footprints overlap on the x/y plane (ignoring layer). Each tile spans
    /// [x, x+2) × [y, y+2) in half-steps.
    private static func planesOverlap(_ a: LayoutSlot, _ b: LayoutSlot) -> Bool {
        let ax0 = a.x, ax1 = a.x + 2, ay0 = a.y, ay1 = a.y + 2
        let bx0 = b.x, bx1 = b.x + 2, by0 = b.y, by1 = b.y + 2
        return ax0 < bx1 && bx0 < ax1 && ay0 < by1 && by0 < ay1
    }

    /// `b` covers `a` from above: strictly higher layer and overlapping plane.
    private static func covers(_ b: LayoutSlot, _ a: LayoutSlot) -> Bool {
        b.layer > a.layer && planesOverlap(a, b)
    }

    /// `b` sits immediately to the side of `a` on the same layer (left/right),
    /// overlapping vertically. Used for the "open on a side" rule.
    private static func sideBlocks(_ a: LayoutSlot, _ b: LayoutSlot, leftSide: Bool) -> Bool {
        guard a.layer == b.layer else { return false }
        // vertical overlap required
        let ay0 = a.y, ay1 = a.y + 2, by0 = b.y, by1 = b.y + 2
        guard ay0 < by1 && by0 < ay1 else { return false }
        if leftSide {
            // b is immediately left of a: b's right edge touches a's left edge.
            return b.x + 2 == a.x || (b.x < a.x && b.x + 2 > a.x)
        } else {
            // b is immediately right of a.
            return a.x + 2 == b.x || (b.x > a.x && b.x < a.x + 2)
        }
    }

    // MARK: Free-tile computation

    /// Returns true if the tile at `tiles[index]` is currently free.
    func isFree(at index: Int) -> Bool {
        guard tiles.indices.contains(index) else { return false }
        let me = tiles[index]
        guard !me.removed else { return false }
        guard slots.indices.contains(me.slotIndex) else { return false }
        let mySlot = slots[me.slotIndex]

        var coveredAbove = false
        var blockedLeft = false
        var blockedRight = false

        for other in tiles where !other.removed && other.id != me.id {
            guard slots.indices.contains(other.slotIndex) else { continue }
            let s = slots[other.slotIndex]
            if Board.covers(s, mySlot) {
                coveredAbove = true
                break   // covered from above → not free, stop early
            }
            if !blockedLeft && Board.sideBlocks(mySlot, s, leftSide: true) { blockedLeft = true }
            if !blockedRight && Board.sideBlocks(mySlot, s, leftSide: false) { blockedRight = true }
        }
        if coveredAbove { return false }
        // Free if at least one side (left or right) is open.
        return !(blockedLeft && blockedRight)
    }

    /// All currently-free, not-removed tiles.
    func freeTiles() -> [PlacedTile] {
        tiles.indices.compactMap { isFree(at: $0) ? tiles[$0] : nil }
    }

    /// Set of instance ids that are currently free.
    func freeIDs() -> Set<Int> {
        var out = Set<Int>()
        for i in tiles.indices where isFree(at: i) { out.insert(tiles[i].id) }
        return out
    }

    // MARK: Matching

    /// True if two distinct ids are both free and form a legal match.
    func canMatch(_ idA: Int, _ idB: Int) -> Bool {
        guard idA != idB else { return false }
        guard let ia = indexByID[idA], let ib = indexByID[idB] else { return false }
        guard !tiles[ia].removed, !tiles[ib].removed else { return false }
        guard isFree(at: ia), isFree(at: ib) else { return false }
        return tiles[ia].face.matches(tiles[ib].face)
    }

    /// Remove a matched pair. Returns false (no mutation) if illegal.
    @discardableResult
    mutating func remove(_ idA: Int, _ idB: Int) -> Bool {
        guard canMatch(idA, idB) else { return false }
        guard let ia = indexByID[idA], let ib = indexByID[idB] else { return false }
        tiles[ia].removed = true
        tiles[ib].removed = true
        return true
    }

    mutating func restore(_ idA: Int, _ idB: Int) {
        let map = indexByID
        if let ia = map[idA] { tiles[ia].removed = false }
        if let ib = map[idB] { tiles[ib].removed = false }
    }

    // MARK: Available moves / hints

    /// Returns one available matching pair of free tile ids, if any (the first
    /// match group that has two or more free tiles). Used by hint and by
    /// dead-end detection.
    func availableMatch() -> (Int, Int)? {
        let free = freeTiles()
        guard !free.isEmpty else { return nil }
        // Group free tiles by match group.
        var byGroup: [String: [PlacedTile]] = [:]
        for t in free { byGroup[t.face.matchGroup, default: []].append(t) }
        for (_, group) in byGroup where group.count >= 2 {
            return (group[0].id, group[1].id)
        }
        return nil
    }

    /// All available matching pairs (unique unordered pairs).
    func allAvailableMatches() -> [(Int, Int)] {
        let free = freeTiles()
        var byGroup: [String: [PlacedTile]] = [:]
        for t in free { byGroup[t.face.matchGroup, default: []].append(t) }
        var out: [(Int, Int)] = []
        for (_, group) in byGroup where group.count >= 2 {
            for i in 0..<group.count {
                for j in (i + 1)..<group.count {
                    out.append((group[i].id, group[j].id))
                }
            }
        }
        return out
    }

    var hasAvailableMatch: Bool { availableMatch() != nil }
    var isDeadEnd: Bool { !isCleared && !hasAvailableMatch }

    // MARK: Reshuffle of remaining tiles

    /// Re-assigns the faces of the *remaining* (not-removed) tiles to the same
    /// remaining slots using a solvable backward-deal over the current sub-board,
    /// preserving solvability where possible. Returns a new Board on success.
    func reshuffled(using rng: inout SeededRNG) -> Board? {
        let remaining = tiles.filter { !$0.removed }
        guard !remaining.isEmpty, remaining.count % 2 == 0 else { return nil }
        let remainingSlotIndices = remaining.map { $0.slotIndex }
        let faces = remaining.map { $0.face }

        // Build a solvable assignment of `faces` onto `remainingSlotIndices`
        // using the same forward-removal engine, constrained to this sub-set.
        if let assignment = SolvableDealer.dealFaces(
            faces: faces,
            slots: slots,
            ontoSlotIndices: remainingSlotIndices,
            rng: &rng
        ) {
            var newTiles = tiles
            // Map slotIndex -> position in tiles for O(1) updates.
            var posBySlot: [Int: Int] = [:]
            for (i, t) in newTiles.enumerated() { posBySlot[t.slotIndex] = i }
            for (slotIdx, face) in assignment {
                guard let placedIdx = posBySlot[slotIdx] else { continue }
                newTiles[placedIdx] = PlacedTile(
                    id: newTiles[placedIdx].id,
                    face: face,
                    slotIndex: slotIdx,
                    removed: false
                )
            }
            return Board(layout: layout, slots: slots, tiles: newTiles)
        }
        return nil
    }
}
