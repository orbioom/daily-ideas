import Foundation

/// Monophonic pitch detection using the YIN difference function with parabolic
/// interpolation. Returns a frequency and a clarity score (0...1). Pure Swift.
struct PitchDetector {
    var sampleRate: Double = 44100
    var threshold: Float = 0.15
    var minFrequency: Double = 27.5     // A0
    var maxFrequency: Double = 1500     // above a violin's high E

    /// Detect the fundamental frequency in a buffer of mono samples.
    /// Returns nil when the signal is too quiet or no clear pitch is found.
    func detect(_ samples: [Float]) -> (frequency: Double, clarity: Double)? {
        let n = samples.count
        guard n > 1024 else { return nil }

        // Gate on RMS so silence/noise doesn't produce a phantom pitch.
        var sumSq: Float = 0
        for s in samples { sumSq += s * s }
        let rms = sqrt(sumSq / Float(n))
        guard rms > 0.01 else { return nil }

        let maxTau = min(n / 2, Int(sampleRate / minFrequency))
        let minTau = max(2, Int(sampleRate / maxFrequency))
        guard maxTau > minTau else { return nil }

        var difference = [Float](repeating: 0, count: maxTau)
        // Difference function.
        for tau in minTau..<maxTau {
            var sum: Float = 0
            var i = 0
            while i < n - maxTau {
                let delta = samples[i] - samples[i + tau]
                sum += delta * delta
                i += 1
            }
            difference[tau] = sum
        }

        // Cumulative mean normalized difference.
        var cmnd = [Float](repeating: 1, count: maxTau)
        var runningSum: Float = 0
        for tau in minTau..<maxTau {
            runningSum += difference[tau]
            cmnd[tau] = runningSum > 0 ? difference[tau] * Float(tau - minTau + 1) / runningSum : 1
        }

        // Absolute threshold: first tau under threshold, then refine.
        var tauEstimate = -1
        var tau = minTau
        while tau < maxTau {
            if cmnd[tau] < threshold {
                while tau + 1 < maxTau && cmnd[tau + 1] < cmnd[tau] { tau += 1 }
                tauEstimate = tau
                break
            }
            tau += 1
        }

        // Fall back to global minimum if nothing crossed the threshold.
        if tauEstimate == -1 {
            var minVal = Float.greatestFiniteMagnitude
            for t in minTau..<maxTau where cmnd[t] < minVal {
                minVal = cmnd[t]; tauEstimate = t
            }
            if tauEstimate == -1 || minVal > 0.6 { return nil }
        }

        // Parabolic interpolation around the estimate for sub-sample accuracy.
        let betterTau = parabolicRefine(cmnd, around: tauEstimate, minTau: minTau, maxTau: maxTau)
        guard betterTau > 0 else { return nil }
        let frequency = sampleRate / betterTau
        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }
        let clarity = Double(max(0, 1 - cmnd[tauEstimate]))
        return (frequency, clarity)
    }

    private func parabolicRefine(_ cmnd: [Float], around tau: Int, minTau: Int, maxTau: Int) -> Double {
        guard tau > minTau, tau < maxTau - 1 else { return Double(tau) }
        let s0 = cmnd[tau - 1], s1 = cmnd[tau], s2 = cmnd[tau + 1]
        let denom = (2 * (2 * s1 - s2 - s0))
        guard denom != 0 else { return Double(tau) }
        let adjustment = Double((s2 - s0) / denom)
        return Double(tau) + adjustment
    }
}
