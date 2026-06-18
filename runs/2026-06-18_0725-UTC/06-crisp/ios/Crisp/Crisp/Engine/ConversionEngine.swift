import Foundation

/// Pure conversion engine: oven→air-fryer recipe conversion plus unit helpers.
/// Every conversion is guarded and clamped to sane ranges.
enum ConversionEngine {

    struct OvenToAirFryer: Equatable {
        let airFryerTempF: Int
        let airFryerMinutes: Int
        let tempDropF: Int
        let timeFactor: Double
    }

    /// Standard rule of thumb: lower the temperature ~25°F and cut time ~20%.
    /// Inputs are clamped so a user typo can't produce nonsense or crash.
    static func ovenToAirFryer(ovenTempF: Int, ovenMinutes: Int) -> OvenToAirFryer {
        let safeTemp = min(max(ovenTempF, 150), 550)
        let safeMinutes = min(max(ovenMinutes, 1), 600)

        // Round the air-fryer temp to the nearest 5°F for a clean dial number.
        let loweredRaw = safeTemp - 25
        let airTemp = max(150, Int((Double(loweredRaw) / 5).rounded()) * 5)

        let scaled = Double(safeMinutes) * 0.8
        let airMinutes = max(1, Int(scaled.rounded()))

        return OvenToAirFryer(
            airFryerTempF: airTemp,
            airFryerMinutes: airMinutes,
            tempDropF: 25,
            timeFactor: 0.8
        )
    }

    // MARK: - Unit conversions (guarded)

    static func fahrenheitToCelsius(_ f: Double) -> Double {
        (f - 32) * 5 / 9
    }

    static func celsiusToFahrenheit(_ c: Double) -> Double {
        c * 9 / 5 + 32
    }

    static let gramsPerOunce = 28.349523125

    static func gramsToOunces(_ g: Double) -> Double {
        g / gramsPerOunce   // constant, always non-zero
    }

    static func ouncesToGrams(_ oz: Double) -> Double {
        oz * gramsPerOunce
    }
}
