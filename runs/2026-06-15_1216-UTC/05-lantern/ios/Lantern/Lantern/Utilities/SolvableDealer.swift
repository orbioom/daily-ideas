import Foundation

/// Generates **guaranteed-solvable** Mahjong solitaire boards.
///
/// ## Method: forward-removal simulation ("solve the empty layout, then dress it")
/// Instead of dealing random faces and hoping the board is solvable, we *build*
/// a known solution by simulating a complete solve of the layout's geometry, then
/// dress that solution with matching tile faces:
///
///  1. Treat the layout as fully populated (every slot has an anonymous tile).
///  2. Repeatedly find the tiles that are **currently free** — using the exact
///     same rule the live board uses (nothing on a higher overlapping layer, and
///     at least one horizontal side open) — pick two at random, and remove them.
///     Record the removal order.
///  3. Continue until every tile is removed. The recorded removal order is, by
///     definition, a valid full solution of the layout.
///  4. Walk the removal order and assign each removed pair a matching face-pair
///     drawn from the standard set (faces are pre-grouped into matchable pairs;
///     Flowers/Seasons pair within their any-of-group rule).
///
/// Replaying that same order on the dealt board clears it, so the board is
/// solvable by construction. A random removal order can occasionally strand
/// tiles before the board is empty (no two free tiles remain); we simply retry
/// with a fresh order, capped at an attempt limit. If every attempt fails (does
/// not happen for the shipped layouts in testing), a fully-filled, always-valid
/// fallback board is returned so the caller never fails — that board is still
/// fully playable with shuffle/undo.
///
/// This was validated by porting the geometry + dealer to a reference solver and
/// confirming 0 unsolvable boards across 150 seeds per layout (see README).
enum SolvableDealer {

    /// Deal a full solvable board for `layout` using `rng`.
    static func deal(layout: LayoutKind, rng: inout SeededRNG) -> Board {
        let slots = layout.slots
        let faces = makePairedFaces(count: slots.count, rng: &rng)
        let allIndices = Array(slots.indices)

        if let assignment = dealFaces(faces: faces, slots: slots, ontoSlotIndices: allIndices, rng: &rng) {
            let tiles = buildTiles(slots: slots, assignment: assignment)
            return Board(layout: layout, slots: slots, tiles: tiles)
        }

        // Guaranteed fallback: assign paired faces directly (board is filled and
        // valid; solvability not proven but it is always playable with shuffle).
        var fallbackAssignment: [(Int, TileFace)] = []
        var pool = faces
        for idx in allIndices {
            let f = pool.isEmpty ? TileFace.bamboo(1) : pool.removeFirst()
            fallbackAssignment.append((idx, f))
        }
        let tiles = buildTiles(slots: slots, assignment: fallbackAssignment)
        return Board(layout: layout, slots: slots, tiles: tiles)
    }

    /// Core forward-removal deal. Returns a solvable slot→face assignment, or nil.
    /// `ontoSlotIndices` is the set of slot indices to fill (a subset is allowed,
    /// used by reshuffle). `faces` must be a valid paired multiset of the same
    /// count, in arbitrary order.
    static func dealFaces(faces: [TileFace],
                          slots: [LayoutSlot],
                          ontoSlotIndices: [Int],
                          rng: inout SeededRNG) -> [(Int, TileFace)]? {
        let target = ontoSlotIndices.count
        guard target == faces.count, target % 2 == 0, target > 0 else { return nil }

        let maxAttempts = 24
        for _ in 0..<maxAttempts {
            if let result = attemptDeal(faces: faces, slots: slots,
                                        ontoSlotIndices: ontoSlotIndices, rng: &rng) {
                return result
            }
        }
        return nil
    }

    // MARK: - One attempt (forward-removal method)

    /// Simulate *solving* a fully-present board: repeatedly pick two currently
    /// free tiles and remove them, recording the removal order. The recorded
    /// order is, by construction, a valid solution. We then assign a matching
    /// face-pair to each removed pair, so replaying the same order clears the
    /// board — i.e. the deal is guaranteed solvable.
    ///
    /// Returns slot→face assignment, or nil if this attempt strands tiles (a
    /// random removal order can dead-end; the caller retries).
    private static func attemptDeal(faces: [TileFace],
                                    slots: [LayoutSlot],
                                    ontoSlotIndices: [Int],
                                    rng: inout SeededRNG) -> [(Int, TileFace)]? {
        let allowed = Set(ontoSlotIndices)
        // present[slotIndex] = true while the tile still sits on the board.
        var present = [Bool](repeating: false, count: slots.count)
        for idx in ontoSlotIndices where slots.indices.contains(idx) { present[idx] = true }

        // Group the faces into matchable pairs (e.g. two bamboo-3, or flower+flower).
        guard let pairs = makePairs(from: faces, rng: &rng) else { return nil }

        let pairCount = ontoSlotIndices.count / 2
        guard pairs.count == pairCount else { return nil }

        // Record the removal order as slot-index pairs.
        var removalOrder: [(Int, Int)] = []
        removalOrder.reserveCapacity(pairCount)

        for _ in 0..<pairCount {
            // Tiles that are free right now (mirrors the live free rule exactly).
            var free = freeSlots(slots: slots, allowed: allowed, present: present)
            guard free.count >= 2 else { return nil }
            free.shuffle(using: &rng)
            let a = free[0]
            let b = free[1]
            // Both are simultaneously free now, so removing this pair is a valid
            // solution step regardless of which faces we assign to them.
            removalOrder.append((a, b))
            present[a] = false
            present[b] = false
        }

        // Every allowed slot must now be removed (board fully solved).
        for idx in ontoSlotIndices where present[idx] { return nil }

        // Assign one matching face-pair to each removed slot-pair.
        var assignment: [(Int, TileFace)] = []
        assignment.reserveCapacity(ontoSlotIndices.count)
        for (i, slotPair) in removalOrder.enumerated() {
            let face = pairs[i]
            assignment.append((slotPair.0, face.0))
            assignment.append((slotPair.1, face.1))
        }
        return assignment
    }

    /// Partition a paired face multiset into concrete matching pairs. Returns nil
    /// if the multiset cannot be perfectly paired (shouldn't happen for our sets).
    private static func makePairs(from faces: [TileFace], rng: inout SeededRNG) -> [(TileFace, TileFace)]? {
        // Bucket by match group, then take two at a time from each bucket.
        var buckets: [String: [TileFace]] = [:]
        for f in faces { buckets[f.matchGroup, default: []].append(f) }
        var pairs: [(TileFace, TileFace)] = []
        for (_, var items) in buckets {
            guard items.count % 2 == 0 else { return nil }
            while items.count >= 2 {
                let a = items.removeLast()
                let b = items.removeLast()
                pairs.append((a, b))
            }
        }
        pairs.shuffle(using: &rng)
        return pairs
    }

    /// Slots whose tile is currently free: present, in `allowed`, not covered by
    /// a present higher tile, and open on at least one horizontal side. This is
    /// the exact same rule the live `Board` uses, so the recorded removal order
    /// is a real, replayable solution.
    private static func freeSlots(slots: [LayoutSlot],
                                  allowed: Set<Int>,
                                  present: [Bool]) -> [Int] {
        var result: [Int] = []
        for idx in allowed where present[idx] {
            guard slots.indices.contains(idx) else { continue }
            let me = slots[idx]
            var coveredAbove = false
            var blockedLeft = false
            var blockedRight = false
            for other in allowed where other != idx && present[other] {
                guard slots.indices.contains(other) else { continue }
                let s = slots[other]
                if covers(s, me) { coveredAbove = true; break }
                if !blockedLeft && sideBlocks(me, s, leftSide: true) { blockedLeft = true }
                if !blockedRight && sideBlocks(me, s, leftSide: false) { blockedRight = true }
            }
            if coveredAbove { continue }
            if blockedLeft && blockedRight { continue }
            result.append(idx)
        }
        return result
    }

    // MARK: - Geometry (mirrors Board's rules exactly)

    private static func planesOverlap(_ a: LayoutSlot, _ b: LayoutSlot) -> Bool {
        let ax0 = a.x, ax1 = a.x + 2, ay0 = a.y, ay1 = a.y + 2
        let bx0 = b.x, bx1 = b.x + 2, by0 = b.y, by1 = b.y + 2
        return ax0 < bx1 && bx0 < ax1 && ay0 < by1 && by0 < ay1
    }
    private static func covers(_ b: LayoutSlot, _ a: LayoutSlot) -> Bool {
        b.layer > a.layer && planesOverlap(a, b)
    }
    private static func sideBlocks(_ a: LayoutSlot, _ b: LayoutSlot, leftSide: Bool) -> Bool {
        guard a.layer == b.layer else { return false }
        let ay0 = a.y, ay1 = a.y + 2, by0 = b.y, by1 = b.y + 2
        guard ay0 < by1 && by0 < ay1 else { return false }
        if leftSide {
            return b.x + 2 == a.x || (b.x < a.x && b.x + 2 > a.x)
        } else {
            return a.x + 2 == b.x || (b.x > a.x && b.x < a.x + 2)
        }
    }

    // MARK: - Face pairing

    /// Build a paired multiset of faces of the given count, drawn from the
    /// standard 144 set. For counts < 144 we take a prefix of a shuffled standard
    /// set but always keep faces in matchable pairs (Flowers/Seasons handled as
    /// their own groups). Result count is exactly `count` (even).
    static func makePairedFaces(count: Int, rng: inout SeededRNG) -> [TileFace] {
        precondition(count % 2 == 0, "Tile count must be even")
        if count == 144 {
            var faces = TileSet.standardFaces()
            faces.shuffle(using: &rng)
            return faces
        }
        // For smaller boards, build `count/2` pairs. Cycle through the distinct
        // match-group representatives, taking two copies of each, until we have
        // enough. This guarantees every face has a partner in the set.
        let reps = distinctRepresentatives()
        var pairs: [TileFace] = []
        var i = 0
        while pairs.count < count {
            let rep = reps[i % reps.count]
            pairs.append(rep)
            pairs.append(rep)
            i += 1
        }
        var trimmed = Array(pairs.prefix(count))
        trimmed.shuffle(using: &rng)
        return trimmed
    }

    /// One representative face per distinct numbered/honor face. (Flowers/Seasons
    /// collapsed to a single representative each since any-of-group matches.)
    private static func distinctRepresentatives() -> [TileFace] {
        var reps: [TileFace] = []
        for n in 1...9 {
            reps.append(.bamboo(n))
            reps.append(.characters(n))
            reps.append(.circles(n))
        }
        for w in TileFace.Wind.allCases { reps.append(.wind(w)) }
        for d in TileFace.Dragon.allCases { reps.append(.dragon(d)) }
        reps.append(.flower(.plum))
        reps.append(.season(.spring))
        return reps
    }

    // MARK: - Tile building

    private static func buildTiles(slots: [LayoutSlot], assignment: [(Int, TileFace)]) -> [PlacedTile] {
        // assignment may not be ordered by slot; place by slot index, assign ids.
        var faceForSlot = [Int: TileFace]()
        for (slotIdx, face) in assignment { faceForSlot[slotIdx] = face }
        var tiles: [PlacedTile] = []
        var nextID = 0
        for idx in slots.indices {
            let face = faceForSlot[idx] ?? .bamboo(1)
            tiles.append(PlacedTile(id: nextID, face: face, slotIndex: idx, removed: false))
            nextID += 1
        }
        return tiles
    }
}
