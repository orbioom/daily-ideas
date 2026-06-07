import Foundation

/// Consistent number formatting for the energy dashboards. Mono-friendly strings.
enum Fmt {

    /// A whole number with thousands separators, e.g. 1,240.
    static func int(_ value: Double) -> String {
        let v = value.isFinite ? value : 0
        return whole.string(from: NSNumber(value: v.rounded())) ?? "0"
    }

    /// One decimal place, e.g. 4.5.
    static func dec1(_ value: Double) -> String {
        let v = value.isFinite ? value : 0
        return one.string(from: NSNumber(value: v)) ?? "0"
    }

    /// Watt-hours, rounded, with unit, e.g. "1,240 Wh".
    static func wh(_ value: Double) -> String { "\(int(value)) Wh" }

    /// Amp-hours, one decimal, with unit, e.g. "103.4 Ah".
    static func ah(_ value: Double) -> String { "\(dec1(value)) Ah" }

    static func watts(_ value: Double) -> String { "\(int(value)) W" }

    /// Days of autonomy, handling the infinite case for self-sustaining systems.
    static func days(_ value: Double) -> String {
        guard value.isFinite else { return "∞" }
        return value >= 100 ? "99+" : dec1(value)
    }

    /// Hours with a unit, handling the infinite (never-recharges) case.
    static func hours(_ value: Double) -> String {
        guard value.isFinite else { return "∞" }
        return "\(dec1(value)) h"
    }

    /// Signed watt-hours, for the solar net figure, e.g. "+312 Wh" / "−540 Wh".
    static func signedWh(_ value: Double) -> String {
        let v = value.isFinite ? value : 0
        let sign = v >= 0 ? "+" : "−"
        return "\(sign)\(int(abs(v))) Wh"
    }

    static func percent(_ fraction: Double) -> String {
        let v = (fraction.isFinite ? fraction : 0) * 100
        return "\(int(v))%"
    }

    private static let whole: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let one: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()
}
