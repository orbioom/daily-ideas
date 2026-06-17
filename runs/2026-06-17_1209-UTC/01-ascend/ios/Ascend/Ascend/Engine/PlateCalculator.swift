import Foundation

/// Greedy per-side plate breakdown for a barbell. Works on canonical kg
/// (callers convert available plates to kg before calling).
enum PlateCalculator {

    struct Result {
        /// Plates for ONE side, largest first (kg each).
        let perSide: [Double]
        /// Weight actually achievable with the available plates (kg).
        let achievableTotalKg: Double
        /// Leftover that could not be matched by plates (kg, both sides).
        let remainderKg: Double

        var isExact: Bool { remainderKg < 0.01 }
    }

    /// Break `targetKg` into plates per side given `barKg` and an available plate set (kg, per plate).
    /// Assumes plates come in pairs.
    static func breakdown(targetKg: Double, barKg: Double, availableKg: [Double]) -> Result {
        let target = max(targetKg, 0)
        // Nothing to load below the bar.
        guard target > barKg else {
            return Result(perSide: [], achievableTotalKg: min(barKg, target), remainderKg: 0)
        }
        var perSideTarget = (target - barKg) / 2.0
        let plates = availableKg.filter { $0 > 0 }.sorted(by: >)
        var used: [Double] = []
        for plate in plates {
            // Add as many of this plate as fit on one side.
            while perSideTarget + 0.001 >= plate {
                used.append(plate)
                perSideTarget -= plate
            }
        }
        let loadedPerSide = used.reduce(0, +)
        let achievable = barKg + loadedPerSide * 2
        let remainder = max(target - achievable, 0)
        return Result(perSide: used, achievableTotalKg: achievable, remainderKg: remainder)
    }

    /// Default plate sets per unit (each value is one plate's mass in that unit).
    static func defaultPlates(for unit: WeightUnit) -> [Double] {
        switch unit {
        case .kg: return [25, 20, 15, 10, 5, 2.5, 1.25]
        case .lb: return [45, 35, 25, 10, 5, 2.5]
        }
    }

    /// Default bar mass in kg per unit (20 kg / 45 lb).
    static func defaultBarKg(for unit: WeightUnit) -> Double {
        unit == .kg ? 20 : 45 * Units.kgPerLb
    }
}
