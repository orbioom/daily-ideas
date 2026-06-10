import Foundation

/// Fundamental-frequency detection via the normalized square-difference function
/// (a robust autocorrelation variant), with parabolic interpolation for sub-bin
/// accuracy. Returns nil on silence or when no clear pitch is found.
struct PitchDetector {
    let sampleRate: Double
    let minFrequency: Double
    let maxFrequency: Double
    /// RMS gate: below this the signal is treated as silence.
    let amplitudeThreshold: Float

    init(sampleRate: Double, minFrequency: Double = 40, maxFrequency: Double = 1500,
         amplitudeThreshold: Float = 0.012) {
        self.sampleRate = sampleRate
        self.minFrequency = minFrequency
        self.maxFrequency = maxFrequency
        self.amplitudeThreshold = amplitudeThreshold
    }

    /// Returns (frequency, amplitude) or nil if no confident pitch.
    func detect(_ samples: [Float]) -> (frequency: Double, amplitude: Float)? {
        let n = samples.count
        guard n > 1024 else { return nil }

        // Amplitude (RMS) gate.
        var sumSq: Float = 0
        for s in samples { sumSq += s * s }
        let rms = (sumSq / Float(n)).squareRoot()
        guard rms >= amplitudeThreshold else { return nil }

        let minLag = max(1, Int(sampleRate / maxFrequency))
        let maxLag = min(n - 1, Int(sampleRate / minFrequency))
        guard maxLag > minLag else { return nil }

        // Normalized square difference function (McLeod-style).
        var bestLag = -1
        var bestValue: Double = 0
        var nsdf = [Double](repeating: 0, count: maxLag + 1)

        for lag in minLag...maxLag {
            var acf: Double = 0
            var energy: Double = 0
            var i = 0
            while i + lag < n {
                let a = Double(samples[i])
                let b = Double(samples[i + lag])
                acf += a * b
                energy += a * a + b * b
                i += 1
            }
            let value = energy > 0 ? 2.0 * acf / energy : 0
            nsdf[lag] = value
        }

        // Find the first major peak above a threshold (avoids octave errors).
        let peakThreshold = 0.86
        var lag = minLag
        // Skip the initial descent from the zero-lag region.
        while lag < maxLag && nsdf[lag] > 0 { lag += 1 }
        while lag < maxLag {
            if nsdf[lag] > peakThreshold {
                // Track to the local maximum of this peak.
                var localBest = lag
                while lag < maxLag && nsdf[lag + 1] >= nsdf[lag] { lag += 1; localBest = lag }
                bestLag = localBest
                bestValue = nsdf[localBest]
                break
            }
            lag += 1
        }

        // Fallback: global maximum if no peak crossed the threshold.
        if bestLag < 0 {
            for l in minLag...maxLag where nsdf[l] > bestValue { bestValue = nsdf[l]; bestLag = l }
            guard bestValue > 0.6 else { return nil }
        }
        guard bestLag > 0 else { return nil }

        // Parabolic interpolation around bestLag for finer frequency.
        let refinedLag = parabolicPeak(nsdf, around: bestLag, lo: minLag, hi: maxLag)
        let frequency = sampleRate / refinedLag
        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }
        return (frequency, rms)
    }

    private func parabolicPeak(_ data: [Double], around i: Int, lo: Int, hi: Int) -> Double {
        guard i > lo, i < hi else { return Double(i) }
        let y0 = data[i - 1], y1 = data[i], y2 = data[i + 1]
        let denom = (y0 - 2 * y1 + y2)
        guard abs(denom) > 1e-12 else { return Double(i) }
        let offset = 0.5 * (y0 - y2) / denom
        return Double(i) + offset
    }
}
