import SwiftUI

/// Persisted preferences that change app behavior. Plate set is stored as a comma list.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("weightUnitRaw") var weightUnitRaw: String = WeightUnit.kg.rawValue
    @AppStorage("barWeightKg") var barWeightKg: Double = 20
    @AppStorage("defaultRestSeconds") var defaultRestSeconds: Int = 150
    @AppStorage("autoProgression") var autoProgression: Bool = true
    /// Available plates stored as canonical kg, comma-separated.
    @AppStorage("plateSetKg") private var plateSetRaw: String = "25,20,15,10,5,2.5,1.25"

    var unit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    /// Available plates in kg, largest first.
    var plateSetKg: [Double] {
        get {
            let parsed = plateSetRaw
                .split(separator: ",")
                .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                .filter { $0 > 0 }
                .sorted(by: >)
            return parsed.isEmpty ? PlateCalculator.defaultPlates(for: .kg) : parsed
        }
        set {
            let clean = newValue.filter { $0 > 0 }.sorted(by: >)
            plateSetRaw = clean.map { Units.trimmed($0) }.joined(separator: ",")
        }
    }

    func addPlate(displayValue: Double) {
        let kg = Units.fromDisplay(displayValue, unit: unit)
        guard kg > 0 else { return }
        var set = plateSetKg
        if !set.contains(where: { abs($0 - kg) < 0.001 }) {
            set.append(kg)
            plateSetKg = set
        }
    }

    func removePlate(_ kg: Double) {
        plateSetKg = plateSetKg.filter { abs($0 - kg) >= 0.001 }
    }

    func resetPlates() {
        plateSetKg = PlateCalculator.defaultPlates(for: unit).map {
            Units.fromDisplay($0, unit: unit)
        }
    }

    /// Convenience formatters bound to the chosen unit.
    func weight(_ kg: Double) -> String { Units.formatWeight(kg, unit: unit) }
    func number(_ kg: Double) -> String { Units.formatNumber(kg, unit: unit) }
}
