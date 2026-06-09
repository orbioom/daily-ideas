import Foundation

/// Small, dependency-free formatting helpers shared across the app so number and
/// date presentation stays consistent.
enum Format {
    /// "1,240" style grouped integer.
    static func int(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "Mar 4, 2026"
    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    /// "Mar 4"
    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    /// "2h 15m" / "45m" from a minute count.
    static func duration(minutes: Int) -> String {
        guard minutes > 0 else { return "0m" }
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// "82%" from a 0…1 fraction.
    static func percent(_ fraction: Double) -> String {
        "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }

    /// "4.3" style one-decimal value.
    static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
