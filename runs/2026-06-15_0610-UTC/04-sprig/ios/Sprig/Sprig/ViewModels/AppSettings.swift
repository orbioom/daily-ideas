import SwiftUI

/// Which growth reference label the app presents. WHO 0–5y is the underlying data either way;
/// this affects the displayed standard name only (an honest, explicit choice for parents).
enum GrowthStandardChoice: String, CaseIterable, Identifiable, Codable {
    case who
    case cdc
    var id: String { rawValue }
    var label: String { self == .who ? "WHO (0–5 yrs)" : "CDC-style label" }
    var short: String { self == .who ? "WHO" : "CDC" }
}

/// Persisted user preferences that actually change behavior across the app.
@MainActor
final class AppSettings: ObservableObject {
    /// Weight display unit — converts every weight readout/input app-wide.
    @AppStorage("massUnit") private var massUnitRaw: String = MassUnit.kg.rawValue
    /// Length display unit — converts every height/head readout/input app-wide.
    @AppStorage("lengthUnit") private var lengthUnitRaw: String = LengthUnit.cm.rawValue
    /// The growth measure shown first on the Growth screen.
    @AppStorage("defaultMeasure") private var defaultMeasureRaw: String = GrowthMeasure.weight.rawValue
    /// Which percentile standard label to display.
    @AppStorage("growthStandard") private var growthStandardRaw: String = GrowthStandardChoice.who.rawValue
    /// Sparse haptics on save/achieve/give actions.
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true

    var massUnit: MassUnit {
        get { MassUnit(rawValue: massUnitRaw) ?? .kg }
        set { massUnitRaw = newValue.rawValue; objectWillChange.send() }
    }

    var lengthUnit: LengthUnit {
        get { LengthUnit(rawValue: lengthUnitRaw) ?? .cm }
        set { lengthUnitRaw = newValue.rawValue; objectWillChange.send() }
    }

    var defaultMeasure: GrowthMeasure {
        get { GrowthMeasure(rawValue: defaultMeasureRaw) ?? .weight }
        set { defaultMeasureRaw = newValue.rawValue; objectWillChange.send() }
    }

    var growthStandard: GrowthStandardChoice {
        get { GrowthStandardChoice(rawValue: growthStandardRaw) ?? .who }
        set { growthStandardRaw = newValue.rawValue; objectWillChange.send() }
    }

    /// Convenience formatter honoring current units.
    func format(_ siValue: Double, measure: GrowthMeasure) -> String {
        UnitConvert.format(siValue, measure: measure, mass: massUnit, length: lengthUnit)
    }

    func unitShort(for measure: GrowthMeasure) -> String {
        UnitConvert.unitShort(for: measure, mass: massUnit, length: lengthUnit)
    }
}
