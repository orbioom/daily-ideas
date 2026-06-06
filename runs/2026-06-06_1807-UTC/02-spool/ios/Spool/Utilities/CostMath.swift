import Foundation

/// Pure conversions between filament mass and length, plus cost helpers.
///
/// length = volume / cross-sectional-area, where
///   volume(cm³) = mass(g) / density(g/cm³)
///   area(cm²)   = π · (diameter_cm / 2)²
enum CostMath {

    /// Cross-sectional area of the filament strand in cm².
    static func areaCm2(diameter: Diameter) -> Double {
        let rCm = (diameter.rawValue / 10.0) / 2.0
        return Double.pi * rCm * rCm
    }

    /// Convert grams of filament to length in meters. Returns 0 for nonsensical input.
    static func lengthMeters(grams: Double, material: Material, diameter: Diameter) -> Double {
        guard grams > 0, material.density > 0 else { return 0 }
        let volumeCm3 = grams / material.density
        let area = areaCm2(diameter: diameter)
        guard area > 0 else { return 0 }
        let lengthCm = volumeCm3 / area
        return lengthCm / 100.0
    }

    /// Convert a length in meters to grams of filament.
    static func grams(meters: Double, material: Material, diameter: Diameter) -> Double {
        guard meters > 0 else { return 0 }
        let lengthCm = meters * 100.0
        let volumeCm3 = lengthCm * areaCm2(diameter: diameter)
        return volumeCm3 * material.density
    }

    /// Estimate how many copies of a part (by grams each) remain on a spool.
    static func partsRemaining(remainingG: Double, gramsPerPart: Double) -> Int {
        guard gramsPerPart > 0 else { return 0 }
        return Int((remainingG / gramsPerPart).rounded(.down))
    }
}
