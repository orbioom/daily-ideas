import Foundation

/// Which ear is being tested. Raw value is persisted in SwiftData.
enum Ear: String, CaseIterable, Identifiable, Codable {
    case right = "Right"
    case left = "Left"
    var id: String { rawValue }
    var short: String { self == .right ? "R" : "L" }
    /// Stereo pan: -1 = full left, +1 = full right.
    var pan: Float { self == .right ? 1.0 : -1.0 }
}

/// Standard audiometric test frequencies (Hz), air-conduction screening.
enum Audiometry {
    static let frequencies: [Int] = [250, 500, 1000, 2000, 4000, 8000]

    /// Frequencies that compose the Pure-Tone Average (PTA): 500 / 1k / 2k / 4k.
    static let ptaFrequencies: [Int] = [500, 1000, 2000, 4000]

    /// The app's relative dB-HL-ish scale. This is NOT clinically calibrated.
    static let minLevel: Double = 0
    static let levelStepDown: Double = 10   // Hughson–Westlake: down 10 after a "heard"
    static let levelStepUp: Double = 5      // up 5 after a "no response"

    /// Average of available PTA-frequency thresholds. Returns nil if none present.
    static func pta(from thresholds: [Int: Double]) -> Double? {
        let vals = ptaFrequencies.compactMap { thresholds[$0] }
        guard !vals.isEmpty else { return nil }
        return vals.reduce(0, +) / Double(vals.count)
    }

    /// Format a frequency for display (e.g. 8000 -> "8 kHz", 500 -> "500 Hz").
    static func label(forFrequency hz: Int) -> String {
        if hz >= 1000 {
            let k = Double(hz) / 1000
            // Show without trailing ".0"
            if k.rounded() == k {
                return "\(Int(k)) kHz"
            }
            return String(format: "%.1f kHz", k)
        }
        return "\(hz) Hz"
    }
}
