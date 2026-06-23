import Foundation

/// Computes a greedy barbell plate loading for one side of the bar.
enum PlateCalculator {
    /// Standard plate denominations (kg and lb) loaded from heaviest down.
    static func plates(for unit: WeightUnit) -> [Double] {
        switch unit {
        case .kg: return [25, 20, 15, 10, 5, 2.5, 1.25]
        case .lb: return [45, 35, 25, 10, 5, 2.5]
        }
    }

    /// A loaded plate with how many go on each side.
    struct Plate: Identifiable {
        let id = UUID()
        let value: Double
        let count: Int
    }

    struct Loading {
        var perSide: [Plate]
        /// Weight that could not be matched with available plates (each side).
        var leftoverPerSide: Double
        var achievable: Double
    }

    /// Given a target total weight and bar weight (same unit), return per-side plates.
    /// Guards against target below bar weight and division issues.
    static func solve(target: Double, barWeight: Double, unit: WeightUnit) -> Loading {
        guard target > barWeight else {
            return Loading(perSide: [], leftoverPerSide: 0, achievable: max(barWeight, target == 0 ? 0 : barWeight))
        }
        var perSide = (target - barWeight) / 2.0
        guard perSide > 0 else {
            return Loading(perSide: [], leftoverPerSide: 0, achievable: barWeight)
        }
        var result: [Plate] = []
        var loadedPerSide = 0.0
        for value in plates(for: unit) {
            guard value > 0 else { continue }
            let count = Int((perSide / value).rounded(.down))
            if count > 0 {
                result.append(Plate(value: value, count: count))
                let used = Double(count) * value
                perSide -= used
                loadedPerSide += used
            }
        }
        let achievable = barWeight + loadedPerSide * 2.0
        return Loading(perSide: result, leftoverPerSide: max(0, perSide), achievable: achievable)
    }
}
