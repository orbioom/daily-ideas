import SwiftUI

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("unitRaw") var unitRaw: String = GlucoseUnit.mgdl.rawValue
    /// Target range bounds, always stored canonically in mg/dL.
    @AppStorage("targetLowMgdl") var targetLowMgdl: Double = 70
    @AppStorage("targetHighMgdl") var targetHighMgdl: Double = 180
    @AppStorage("showA1C") var showA1C: Bool = true

    var unit: GlucoseUnit {
        get { GlucoseUnit(rawValue: unitRaw) ?? .mgdl }
        set { unitRaw = newValue.rawValue }
    }

    /// Defensive accessors so a corrupted/empty preference can never invert the range.
    var safeLow: Double { min(targetLowMgdl, targetHighMgdl) }
    var safeHigh: Double { max(targetLowMgdl, targetHighMgdl) }

    // MARK: Formatting

    /// Format a canonical mg/dL value for display in the chosen unit, without the unit suffix.
    func formatValue(_ mgdl: Double) -> String {
        let v = unit.value(fromMgdl: mgdl)
        return String(format: "%.\(unit.fractionDigits)f", v)
    }

    /// Format a canonical mg/dL value with the unit suffix, e.g. "124 mg/dL".
    func formatValueWithUnit(_ mgdl: Double) -> String {
        "\(formatValue(mgdl)) \(unit.label)"
    }

    /// Spoken accessibility string for a reading value.
    func accessibilityValue(_ mgdl: Double) -> String {
        "\(formatValue(mgdl)) \(unit == .mgdl ? "milligrams per deciliter" : "millimoles per liter")"
    }

    /// Classify a value against the user's current target range.
    func band(for mgdl: Double) -> GlucoseBand {
        GlucoseBand.classify(mgdl: mgdl, low: safeLow, high: safeHigh)
    }

    /// Format the target range itself in the chosen unit, e.g. "70–180 mg/dL".
    func formatRange() -> String {
        "\(formatValue(safeLow))–\(formatValue(safeHigh)) \(unit.label)"
    }
}
