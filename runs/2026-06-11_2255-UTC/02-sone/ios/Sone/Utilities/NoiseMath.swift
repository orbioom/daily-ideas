import Foundation

/// Hearing-safety math following the NIOSH recommended exposure limit:
/// 85 dB(A) over 8 hours with a 3 dB exchange rate.
enum NoiseMath {
    static let criterionLevel = 85.0
    static let criterionHours = 8.0
    static let exchangeRate = 3.0

    /// Maximum daily exposure time at a constant level before reaching 100%
    /// dose. Returns `nil` when the level is safe for unlimited listening.
    static func allowedSeconds(at level: Double) -> TimeInterval? {
        guard level >= 80 else { return nil }
        let hours = criterionHours / pow(2, (level - criterionLevel) / exchangeRate)
        return hours * 3600
    }

    /// Dose contribution (percent of the daily limit) of `seconds` at `level`.
    static func dose(seconds: TimeInterval, at level: Double) -> Double {
        guard let allowed = allowedSeconds(at: level) else { return 0 }
        return seconds / allowed * 100
    }

    /// Energy average (Leq) of a set of levels in dB.
    static func energyAverage(_ levels: [Double]) -> Double {
        guard !levels.isEmpty else { return 0 }
        let mean = levels.reduce(0) { $0 + pow(10, $1 / 10) } / Double(levels.count)
        return 10 * log10(mean)
    }

    static func classify(_ db: Double) -> (label: String, advice: String) {
        switch db {
        case ..<40: return ("Very quiet", "Library-level calm. No risk at all.")
        case ..<55: return ("Quiet", "Comfortable background level.")
        case ..<70: return ("Moderate", "Normal conversation territory. Safe indefinitely.")
        case ..<80: return ("Loud", "Busy traffic level. Safe, but fatiguing over hours.")
        case ..<85: return ("Very loud", "Approaching the NIOSH daily limit threshold.")
        case ..<95: return ("Harmful over time", "Limit exposure — hearing damage accumulates here.")
        case ..<110: return ("Dangerous", "Minutes matter at this level. Use hearing protection.")
        default: return ("Painful", "Immediate risk of hearing damage.")
        }
    }

    static func formatTime(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded()))
        if s < 60 { return "\(s)s" }
        let m = s / 60
        if m < 60 { return s % 60 == 0 ? "\(m) min" : "\(m)m \(s % 60)s" }
        let h = m / 60
        return m % 60 == 0 ? "\(h) h" : "\(h)h \(m % 60)m"
    }

    /// Reference ladder of everyday sounds for the Guide screen.
    static let referenceLevels: [(db: Double, name: String, icon: String)] = [
        (30, "Whisper, quiet library", "book"),
        (40, "Quiet office, light rain", "cloud.drizzle"),
        (50, "Refrigerator hum", "refrigerator"),
        (60, "Normal conversation", "person.2.wave.2"),
        (70, "Dishwasher, busy office", "dishwasher"),
        (75, "Vacuum cleaner", "house"),
        (80, "Heavy city traffic", "car.2"),
        (85, "Blender, food processor", "fork.knife"),
        (90, "Lawn mower, shouted talk", "leaf"),
        (95, "Motorcycle at 25 ft", "figure.outdoor.cycle"),
        (100, "Subway platform, sports bar", "tram"),
        (105, "Maximum headphone volume", "headphones"),
        (110, "Rock concert, chainsaw", "music.mic"),
        (120, "Ambulance siren up close", "cross.case"),
        (130, "Jet engine at 100 ft", "airplane"),
    ]
}
