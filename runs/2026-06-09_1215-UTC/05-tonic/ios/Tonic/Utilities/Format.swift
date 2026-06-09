import Foundation

/// Small, dependency-free formatting helpers shared across screens.
enum Format {
    /// "1m 20s" / "45s" for a duration in seconds.
    static func duration(_ seconds: Int) -> String {
        let s = max(0, seconds)
        if s < 60 { return "\(s)s" }
        let m = s / 60
        let rem = s % 60
        return rem == 0 ? "\(m)m" : "\(m)m \(rem)s"
    }

    /// "78%" from a 0…1 fraction.
    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}
