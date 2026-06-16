import Foundation

/// Oven temperature conversions between Fahrenheit, Celsius and UK gas marks,
/// plus common oven presets.
enum TempEngine {

    static func fahrenheitToCelsius(_ f: Double) -> Double {
        (f - 32) * 5.0 / 9.0
    }

    static func celsiusToFahrenheit(_ c: Double) -> Double {
        c * 9.0 / 5.0 + 32
    }

    /// Gas mark for a given Celsius value (nearest standard mark), or nil if out of range.
    static func gasMark(forCelsius c: Double) -> Int? {
        // Standard gas-mark table (°C → mark).
        let table: [(c: Double, mark: Int)] = [
            (135, 1), (149, 2), (163, 3), (177, 4),
            (191, 5), (204, 6), (218, 7), (232, 8), (246, 9)
        ]
        var best: (Int, Double)? = nil
        for entry in table {
            let d = abs(entry.c - c)
            if let current = best {
                if d < current.1 { best = (entry.mark, d) }
            } else {
                best = (entry.mark, d)
            }
        }
        // Only return a mark when reasonably close (within ~10°C).
        if let best, best.1 <= 12 { return best.0 }
        return nil
    }

    /// Common oven presets used in the Reference screen.
    struct OvenPreset: Identifiable {
        let id = UUID()
        let label: String
        let fahrenheit: Int
        let celsius: Int
        let gasMark: Int
    }

    static let ovenPresets: [OvenPreset] = [
        .init(label: "Very cool",      fahrenheit: 275, celsius: 135, gasMark: 1),
        .init(label: "Cool",          fahrenheit: 300, celsius: 149, gasMark: 2),
        .init(label: "Warm",          fahrenheit: 325, celsius: 163, gasMark: 3),
        .init(label: "Moderate",      fahrenheit: 350, celsius: 177, gasMark: 4),
        .init(label: "Moderately hot", fahrenheit: 375, celsius: 191, gasMark: 5),
        .init(label: "Fairly hot",    fahrenheit: 400, celsius: 204, gasMark: 6),
        .init(label: "Hot",          fahrenheit: 425, celsius: 218, gasMark: 7),
        .init(label: "Very hot",      fahrenheit: 450, celsius: 232, gasMark: 8),
        .init(label: "Hottest",       fahrenheit: 475, celsius: 246, gasMark: 9)
    ]
}
