import Foundation

/// A deterministic dealer that produces 3 pieces at a time from a seeded RNG.
/// The generator state advances each time `deal()` is called, so persisting the number
/// of pieces dealt (`dealtCount`) plus the original `seed` lets us reproduce the exact
/// sequence after relaunch — and the daily challenge seeds from the date.
struct PieceDealer: Codable {
    let seed: UInt64
    /// How many *batches* of 3 have been dealt so far. Advancing the RNG by replaying
    /// from the seed keeps this fully reproducible regardless of device.
    private(set) var batchesDealt: Int

    init(seed: UInt64, batchesDealt: Int = 0) {
        self.seed = seed
        self.batchesDealt = max(0, batchesDealt)
    }

    /// Deal the next 3 pieces, advancing the dealer. Deterministic for a given seed
    /// and `batchesDealt`. Colors and shapes both come from the seeded RNG.
    mutating func dealNext(colorCount: Int) -> [Piece] {
        var rng = rngForCurrentBatch()
        let pieces = (0..<3).map { _ in makePiece(using: &rng, colorCount: colorCount) }
        batchesDealt += 1
        return pieces
    }

    /// Peek the pieces for the current batch without advancing (used to rebuild offered
    /// pieces on resume when only the batch index was persisted).
    func currentBatch(colorCount: Int) -> [Piece] {
        var rng = rngForCurrentBatch()
        return (0..<3).map { _ in makePiece(using: &rng, colorCount: colorCount) }
    }

    // MARK: - Internals

    /// A fresh RNG advanced deterministically to the start of the current batch.
    private func rngForCurrentBatch() -> SplitMix64 {
        var rng = SplitMix64(seed: seed)
        // Each batch consumes a fixed number of draws (shape index + color per piece = 2,
        // ×3 pieces = 6). Replay to reach the current batch boundary.
        let draws = batchesDealt * 6
        for _ in 0..<draws { _ = rng.next() }
        return rng
    }

    private func makePiece(using rng: inout SplitMix64, colorCount: Int) -> Piece {
        let shape = weightedShape(using: &rng)
        let colors = max(1, colorCount)
        let colorIndex = rng.int(colors) + 1
        return Piece(cells: shape.cells, colorIndex: colorIndex)
    }

    private func weightedShape(using rng: inout SplitMix64) -> PieceLibrary.Shape {
        let shapes = PieceLibrary.shapes
        let weights = PieceLibrary.weights
        guard shapes.count == weights.count, !shapes.isEmpty else {
            // Defensive fallback: a single cell.
            return PieceLibrary.Shape("dot", [(0, 0)])
        }
        let total = weights.reduce(0, +)
        guard total > 0 else { return shapes[0] }
        var pick = rng.int(total)
        for (i, w) in weights.enumerated() {
            if pick < w { return shapes[i] }
            pick -= w
        }
        return shapes[shapes.count - 1]
    }
}
