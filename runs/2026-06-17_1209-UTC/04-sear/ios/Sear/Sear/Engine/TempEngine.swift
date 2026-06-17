import Foundation

/// Classifies a cook's current internal temperature against its target.
enum TempEngine {

    /// Classify current internal temp vs target into a DonenessState.
    /// `status` lets a resting/done cook report "resting" regardless of temp.
    static func classify(currentC: Double?, targetC: Double, status: CookStatus) -> DonenessState {
        if status == .resting { return .resting }
        guard let current = currentC else { return .under }
        guard targetC > 0 else { return .under }

        let delta = current - targetC
        // Tolerance for "almost" scales a little with how hot the target is.
        let almostBand = max(targetC * 0.06, 4)   // ~4°C minimum window

        if delta >= 6 {
            return .overcooked
        } else if delta >= -1 {
            return .done
        } else if delta >= -almostBand {
            return .almost
        } else {
            return .under
        }
    }

    /// Degrees remaining to target (>= 0), or nil if no reading yet.
    static func degreesRemainingC(currentC: Double?, targetC: Double) -> Double? {
        guard let current = currentC else { return nil }
        return max(targetC - current, 0)
    }
}
