import Foundation

/// A single pending comparison step: the new place vs an existing one.
struct ComparisonStep: Identifiable, Equatable {
    let id = UUID()
    let existingID: UUID
    let stepNumber: Int          // 1-based, for "comparison N of ~M"
    let estimatedTotal: Int
}

/// Outcome the user taps for a comparison.
enum ComparisonChoice {
    case preferredNew       // the new place is better than the existing one
    case preferredExisting  // the existing place is better
}

/// Drives a binary-search insertion of a new restaurant within its sentiment tier.
/// `candidates` are the existing visited restaurants that share the SAME sentiment tier,
/// already ordered best→worst (ascending rankIndex). The engine narrows [lo, hi) until
/// it converges on an insertion offset within that tier slice.
struct ComparisonSession {
    private let candidateIDs: [UUID]
    private(set) var lo: Int
    private(set) var hi: Int

    init(candidateIDs: [UUID]) {
        self.candidateIDs = candidateIDs
        self.lo = 0
        self.hi = candidateIDs.count
    }

    var isComplete: Bool { lo >= hi }

    /// Insertion offset within the tier slice once complete.
    var insertionOffset: Int { lo }

    private var midIndex: Int { lo + (hi - lo) / 2 }

    var totalSteps: Int { stepCount }

    private var stepCount: Int {
        // Ceil(log2(n+1)) — a safe upper estimate of remaining/total comparisons.
        let n = candidateIDs.count
        if n <= 0 { return 0 }
        var span = n
        var steps = 0
        while span > 0 { steps += 1; span /= 2 }
        return steps
    }

    /// The next pair to show, or nil when complete.
    func nextStep(currentStepNumber: Int) -> ComparisonStep? {
        guard !isComplete else { return nil }
        let mid = midIndex
        guard mid >= 0, mid < candidateIDs.count else { return nil }
        return ComparisonStep(existingID: candidateIDs[mid],
                              stepNumber: currentStepNumber,
                              estimatedTotal: max(stepCount, currentStepNumber))
    }

    /// Apply the user's choice and narrow the bounds.
    mutating func apply(_ choice: ComparisonChoice) {
        guard !isComplete else { return }
        let mid = midIndex
        switch choice {
        case .preferredNew:
            // New is better than candidate[mid] → it belongs at or before mid.
            hi = mid
        case .preferredExisting:
            // Existing is better → new belongs after mid.
            lo = mid + 1
        }
    }
}

enum RankingEngine {

    // MARK: Tier slicing

    /// Restaurants in the SAME sentiment tier as `sentiment`, ordered best→worst.
    static func tierCandidates(in ranked: [Restaurant], sentiment: Sentiment) -> [Restaurant] {
        ranked
            .filter { $0.sentiment == sentiment }
            .sorted { $0.rankIndex < $1.rankIndex }
    }

    /// Build a fresh comparison session for inserting a new place of `sentiment`.
    static func makeSession(in ranked: [Restaurant], sentiment: Sentiment) -> ComparisonSession {
        let ids = tierCandidates(in: ranked, sentiment: sentiment).map(\.id)
        return ComparisonSession(candidateIDs: ids)
    }

    // MARK: Insertion

    /// Compute the final global ordered array after inserting `newcomer` at the converged
    /// offset within its tier. Tiers are concatenated Loved → Liked → Okay so the global
    /// order is always tier-correct.
    static func insertedOrder(ranked: [Restaurant],
                              newcomer: Restaurant,
                              sentiment: Sentiment,
                              tierOffset: Int) -> [Restaurant] {
        // Group existing by tier, preserving best→worst within tier.
        var loved = tierCandidates(in: ranked, sentiment: .loved)
        var liked = tierCandidates(in: ranked, sentiment: .liked)
        var okay = tierCandidates(in: ranked, sentiment: .okay)

        switch sentiment {
        case .loved:
            let off = min(max(tierOffset, 0), loved.count)
            loved.insert(newcomer, at: off)
        case .liked:
            let off = min(max(tierOffset, 0), liked.count)
            liked.insert(newcomer, at: off)
        case .okay:
            let off = min(max(tierOffset, 0), okay.count)
            okay.insert(newcomer, at: off)
        }

        return loved + liked + okay
    }

    /// Re-number rankIndex across the whole ordered array.
    static func reindex(_ ordered: [Restaurant]) {
        for (i, r) in ordered.enumerated() {
            r.rankIndex = i
        }
    }

    // MARK: Score derivation (0...10, tier-banded)

    /// Per-tier score bands so Loved always outscores Liked outscores Okay.
    private static func band(for sentiment: Sentiment) -> (lo: Double, hi: Double) {
        switch sentiment {
        case .loved: return (7.5, 10.0)
        case .liked: return (5.0, 7.4)
        case .okay: return (1.0, 4.9)
        }
    }

    /// Derive a 0...10 score for `restaurant` given the full ordered visited array.
    /// Position within its own tier maps linearly into the tier band; top of tier = band.hi.
    static func score(for restaurant: Restaurant, in ordered: [Restaurant]) -> Double {
        guard let sentiment = restaurant.sentiment else { return 0 }
        let tier = ordered.filter { $0.sentiment == sentiment }
                          .sorted { $0.rankIndex < $1.rankIndex }
        let band = band(for: sentiment)
        guard let pos = tier.firstIndex(where: { $0.id == restaurant.id }) else {
            return band.hi
        }
        let count = tier.count
        if count <= 1 {
            // Lone occupant sits at the top of its band.
            return roundTenth(band.hi)
        }
        // pos 0 → band.hi (best), pos count-1 → band.lo (worst within tier).
        let fraction = Double(pos) / Double(count - 1)
        let raw = band.hi - fraction * (band.hi - band.lo)
        return roundTenth(min(max(raw, band.lo), band.hi))
    }

    private static func roundTenth(_ v: Double) -> Double {
        (v * 10).rounded() / 10
    }
}
