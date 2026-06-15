import Foundation

/// One key's aggregated error statistics for the heatmap.
struct KeyStat: Identifiable, Hashable {
    let key: String          // canonical name: "a"..."z", "space", ",", etc.
    var errorCount: Int
    var attemptCount: Int

    var id: String { key }

    /// Error rate 0...1. Returns 0 when there are no attempts (guarded division).
    var errorRate: Double {
        guard attemptCount > 0 else { return 0 }
        return min(1.0, Double(errorCount) / Double(attemptCount))
    }
}

/// One finger's aggregated error statistics.
struct FingerStat: Identifiable, Hashable {
    let finger: Finger
    var errorCount: Int
    var attemptCount: Int

    var id: String { finger.rawValue }

    var errorRate: Double {
        guard attemptCount > 0 else { return 0 }
        return min(1.0, Double(errorCount) / Double(attemptCount))
    }
}

/// Aggregates per-key and per-finger error rates from a set of `TestResult`s.
///
/// Note: `TestResult` stores per-key *error* counts. Attempt counts per key aren't stored
/// individually, so we estimate attempts proportionally from total chars typed weighted by
/// each key's natural frequency in English. This keeps the heatmap meaningful (errors are
/// normalized rather than just raw counts) without needing per-key attempt logs.
enum KeyHeatmap {
    /// QWERTY rows used by both the heatmap grid and frequency weighting.
    static let row1: [String] = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    static let row2: [String] = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    static let row3: [String] = ["z", "x", "c", "v", "b", "n", "m"]
    static let letterKeys: [String] = row1 + row2 + row3

    /// Relative English letter frequencies (approximate, summing ~1).
    private static let letterFrequency: [String: Double] = [
        "e": 0.127, "t": 0.091, "a": 0.082, "o": 0.075, "i": 0.070,
        "n": 0.067, "s": 0.063, "h": 0.061, "r": 0.060, "d": 0.043,
        "l": 0.040, "c": 0.028, "u": 0.028, "m": 0.024, "w": 0.024,
        "f": 0.022, "g": 0.020, "y": 0.020, "p": 0.019, "b": 0.015,
        "v": 0.010, "k": 0.008, "j": 0.0015, "x": 0.0015, "q": 0.001, "z": 0.0007
    ]

    /// Build per-key stats from results.
    static func keyStats(from results: [TestResult]) -> [String: KeyStat] {
        // Sum errors per key, and total chars across all results.
        var errors: [String: Int] = [:]
        var totalChars = 0
        for r in results {
            totalChars += max(0, r.charCount)
            for (k, c) in r.keyErrors where c > 0 {
                errors[k, default: 0] += c
            }
        }

        var stats: [String: KeyStat] = [:]
        for key in letterKeys {
            let freq = letterFrequency[key] ?? 0.01
            // Estimated attempts for this key; at least the errors observed.
            let estAttempts = max(errors[key] ?? 0, Int((Double(totalChars) * freq).rounded()))
            stats[key] = KeyStat(key: key,
                                 errorCount: errors[key] ?? 0,
                                 attemptCount: estAttempts)
        }
        return stats
    }

    /// Build per-finger stats by folding key stats through the finger map.
    static func fingerStats(from results: [TestResult]) -> [FingerStat] {
        let keyStats = keyStats(from: results)
        var errorByFinger: [Finger: Int] = [:]
        var attemptByFinger: [Finger: Int] = [:]
        for (key, stat) in keyStats {
            guard let first = key.first, let finger = FingerMap.finger(for: first) else { continue }
            errorByFinger[finger, default: 0] += stat.errorCount
            attemptByFinger[finger, default: 0] += stat.attemptCount
        }
        return Finger.allCases.compactMap { finger in
            guard finger != .thumb else { return nil }
            return FingerStat(finger: finger,
                              errorCount: errorByFinger[finger] ?? 0,
                              attemptCount: attemptByFinger[finger] ?? 0)
        }
    }

    /// The single key with the highest error rate (min attempts to avoid noise), if any.
    static func worstKey(from results: [TestResult]) -> KeyStat? {
        let stats = keyStats(from: results).values.filter { $0.errorCount > 0 }
        return stats.max { lhs, rhs in
            if lhs.errorRate == rhs.errorRate { return lhs.errorCount < rhs.errorCount }
            return lhs.errorRate < rhs.errorRate
        }
    }
}
