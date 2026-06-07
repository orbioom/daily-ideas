import Foundation

/// Display helpers shared across screens.
enum Fmt {
    /// Formats a distance stored in feet using the user's unit preference.
    static func distance(feet: Int, units: String) -> String {
        if units == "meters" {
            let m = Double(feet) * 0.3048
            return "\(Int(m.rounded())) m"
        }
        return "\(feet) ft"
    }

    /// A signed relative-to-par string, e.g. "+3", "E", "-2".
    static func relative(_ value: Int) -> String {
        if value == 0 { return "E" }
        return value > 0 ? "+\(value)" : "\(value)"
    }
}
