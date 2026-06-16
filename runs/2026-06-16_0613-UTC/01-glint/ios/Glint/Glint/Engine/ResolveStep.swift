import Foundation

/// One animatable step produced by the engine while resolving a swap.
/// The view replays these in order so cascades read clearly, with an instant
/// fallback when Reduce Motion is on.
enum ResolveStep {
    /// Cells about to clear this wave, plus the score earned and the chain index (1-based).
    case clear(cells: Set<Cell>, score: Int, chain: Int)
    /// A special gem was created at this cell (after a clear wave).
    case spawnSpecial(cell: Cell, gem: Gem)
    /// Gems fell / refilled; the board is now this snapshot.
    case settle(board: Board)
}

/// The full outcome of attempting a swap.
struct SwapOutcome {
    /// False when the swap formed no match and was reverted (no-op swap).
    let didMatch: Bool
    /// Ordered animation steps (empty when no match).
    let steps: [ResolveStep]
    /// Total score gained across all cascades.
    let totalScore: Int
    /// Highest cascade chain reached (for combo banner / haptics).
    let maxChain: Int
    /// Per-color tally of gems cleared (for color-goal levels).
    let clearedByColor: [GemColor: Int]
    /// Total gems cleared (for stats).
    let totalCleared: Int
}
