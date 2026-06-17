import Foundation

/// Pure, testable monophonic pitch detector using NORMALIZED AUTOCORRELATION
/// with parabolic peak interpolation. No AVFoundation dependency — it operates
/// on a plain `[Float]` buffer so it can be unit-tested in isolation.
///
/// Every array access is bounds-checked and every division guards its
/// denominator, so weak / silent / degenerate buffers return `nil` rather than
/// trapping or producing NaNs.
struct PitchDetector: Sendable {

    /// The result of a detection pass.
    struct Result: Equatable, Sendable {
        /// Estimated fundamental frequency in Hz.
        let frequency: Double
        /// Clarity / confidence in 0...1 (normalized peak height).
        let clarity: Double
    }

    // MARK: - Tunables

    /// Below this RMS the signal is treated as silence (no pitch).
    var rmsGate: Float = 0.012
    /// Minimum detectable frequency (Hz). Bounds the longest lag we search.
    var minFrequency: Double = 50
    /// Maximum detectable frequency (Hz). Bounds the shortest lag we search.
    var maxFrequency: Double = 1500
    /// Minimum normalized-autocorrelation peak to accept as a real pitch.
    var clarityThreshold: Double = 0.55

    init() {}

    /// Estimate the fundamental of `samples` recorded at `sampleRate` Hz.
    /// Returns nil when the signal is too weak or no confident peak is found.
    func detect(samples: [Float], sampleRate: Double) -> Result? {
        guard sampleRate > 0, samples.count >= 256 else { return nil }
        let n = samples.count

        // RMS gate — reject silence / very weak input.
        var sumSquares: Double = 0
        for s in samples { sumSquares += Double(s) * Double(s) }
        let rms = (sumSquares / Double(n)).squareRoot()
        guard rms > Double(rmsGate) else { return nil }

        // Lag search window derived from the frequency range.
        guard maxFrequency > 0, minFrequency > 0 else { return nil }
        let minLag = max(1, Int((sampleRate / maxFrequency).rounded(.down)))
        let maxLag = min(n - 1, Int((sampleRate / minFrequency).rounded(.up)))
        guard maxLag > minLag else { return nil }

        // Energy at lag 0 (used to normalize). Guard against zero.
        var energyZero: Double = 0
        for s in samples { energyZero += Double(s) * Double(s) }
        guard energyZero > 0 else { return nil }

        // Normalized autocorrelation across the lag window.
        // r(τ) = Σ x[i]x[i+τ] / sqrt(Σ x[i]² · Σ x[i+τ]²)
        var bestLag = -1
        var bestValue: Double = 0

        // Track whether we've passed the first dip below zero, so we don't lock
        // onto the τ≈0 lobe (a classic autocorrelation octave-error guard).
        var seenNegative = false

        for lag in minLag...maxLag {
            var dot: Double = 0
            var energyLag: Double = 0
            let limit = n - lag
            guard limit > 0 else { continue }
            var i = 0
            while i < limit {
                let a = Double(samples[i])
                let b = Double(samples[i + lag])
                dot += a * b
                energyLag += b * b
                i += 1
            }
            let denom = (energyZero * energyLag).squareRoot()
            guard denom > 0 else { continue }
            let norm = dot / denom

            if norm < 0 { seenNegative = true }

            if seenNegative, norm > bestValue {
                bestValue = norm
                bestLag = lag
            }
        }

        guard bestLag > 0, bestValue >= clarityThreshold else { return nil }

        // Parabolic interpolation around the best lag for sub-sample accuracy.
        let refinedLag = parabolicRefine(samples: samples,
                                         lag: bestLag,
                                         minLag: minLag,
                                         maxLag: maxLag,
                                         energyZero: energyZero)
        guard refinedLag > 0 else { return nil }

        let frequency = sampleRate / refinedLag
        guard frequency.isFinite,
              frequency >= minFrequency,
              frequency <= maxFrequency else { return nil }

        return Result(frequency: frequency, clarity: min(1, max(0, bestValue)))
    }

    /// Parabolic interpolation of the autocorrelation peak using the normalized
    /// correlation values at (lag-1, lag, lag+1). Returns a fractional lag.
    private func parabolicRefine(samples: [Float],
                                 lag: Int,
                                 minLag: Int,
                                 maxLag: Int,
                                 energyZero: Double) -> Double {
        // If the neighbours fall outside the searched window, skip interpolation.
        guard lag - 1 >= minLag, lag + 1 <= maxLag else { return Double(lag) }

        let y0 = normalizedCorrelation(samples: samples, lag: lag - 1, energyZero: energyZero)
        let y1 = normalizedCorrelation(samples: samples, lag: lag, energyZero: energyZero)
        let y2 = normalizedCorrelation(samples: samples, lag: lag + 1, energyZero: energyZero)

        let denom = (y0 - 2 * y1 + y2)
        guard abs(denom) > 1e-12 else { return Double(lag) }
        let delta = 0.5 * (y0 - y2) / denom
        // Clamp the correction to ±1 sample to stay robust.
        let clamped = min(max(delta, -1), 1)
        return Double(lag) + clamped
    }

    /// Single-lag normalized autocorrelation value, bounds- & zero-guarded.
    private func normalizedCorrelation(samples: [Float], lag: Int, energyZero: Double) -> Double {
        let n = samples.count
        let limit = n - lag
        guard lag > 0, limit > 0, energyZero > 0 else { return 0 }
        var dot: Double = 0
        var energyLag: Double = 0
        var i = 0
        while i < limit {
            let a = Double(samples[i])
            let b = Double(samples[i + lag])
            dot += a * b
            energyLag += b * b
            i += 1
        }
        let denom = (energyZero * energyLag).squareRoot()
        guard denom > 0 else { return 0 }
        return dot / denom
    }
}
