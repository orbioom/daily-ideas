import Foundation

/// Small, dependency-free formatting helpers shared across views.
enum Format {
    /// Formats a measured value without trailing zeros (e.g. 45, 12.5).
    static func number(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    /// A short "X of N" day label.
    static func dayOf(_ index: Int, _ total: Int) -> String {
        "Day \(index) of \(total)"
    }
}
