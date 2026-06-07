import Foundation

/// Pure electronics engineering math: Ohm's law, resistor color bands, LED
/// dropper, voltage divider, 555 timer, RC filters, and battery life — plus
/// engineering-notation formatting and E-series snapping.
enum EE {

    // MARK: - Engineering formatting

    /// Format a value with an SI prefix and unit (e.g. 4.7e3 → "4.7 kΩ").
    static func eng(_ value: Double, unit: String, places: Int = 3) -> String {
        guard value.isFinite, value != 0 else { return "0 \(unit)" }
        let neg = value < 0
        var v = abs(value)
        let prefixes: [(Double, String)] = [
            (1e12, "T"), (1e9, "G"), (1e6, "M"), (1e3, "k"),
            (1, ""), (1e-3, "m"), (1e-6, "µ"), (1e-9, "n"), (1e-12, "p")
        ]
        var chosen = ("", 1.0)
        for (scale, p) in prefixes where v >= scale {
            chosen = (p, scale); break
        }
        if v < 1e-12 { chosen = ("p", 1e-12) }
        v /= chosen.1
        let s = trimmed(v, places: places)
        return "\(neg ? "-" : "")\(s) \(chosen.0)\(unit)"
    }

    static func trimmed(_ v: Double, places: Int) -> String {
        let s = String(format: "%.\(places)g", v)
        return s
    }

    // MARK: - E-series

    static let e12: [Double] = [1.0,1.2,1.5,1.8,2.2,2.7,3.3,3.9,4.7,5.6,6.8,8.2]
    static let e24: [Double] = [1.0,1.1,1.2,1.3,1.5,1.6,1.8,2.0,2.2,2.4,2.7,3.0,
                                3.3,3.6,3.9,4.3,4.7,5.1,5.6,6.2,6.8,7.5,8.2,9.1]

    /// Nearest standard value in a series (E12 by default).
    static func nearestStandard(_ value: Double, series: [Double] = e12) -> Double {
        guard value > 0 else { return 0 }
        let decade = pow(10, floor(log10(value)))
        let norm = value / decade
        var best = series.first ?? 1
        var bestErr = Double.greatestFiniteMagnitude
        for candidate in series + [10.0] {
            let err = abs(candidate - norm)
            if err < bestErr { bestErr = err; best = candidate }
        }
        return best * decade
    }

    // MARK: - Ohm's law

    struct Ohm { var v: Double; var i: Double; var r: Double; var p: Double }

    /// Solve Ohm's law given exactly two of voltage/current/resistance/power.
    static func ohm(v: Double?, i: Double?, r: Double?, p: Double?) -> Ohm? {
        if let v, let i { return Ohm(v: v, i: i, r: i != 0 ? v/i : .infinity, p: v*i) }
        if let v, let r { let i = r != 0 ? v/r : .infinity; return Ohm(v: v, i: i, r: r, p: v*i) }
        if let v, let p { let i = v != 0 ? p/v : 0; return Ohm(v: v, i: i, r: i != 0 ? v/i : .infinity, p: p) }
        if let i, let r { let v = i*r; return Ohm(v: v, i: i, r: r, p: v*i) }
        if let i, let p { let v = i != 0 ? p/i : 0; return Ohm(v: v, i: i, r: i != 0 ? v/i : .infinity, p: p) }
        if let r, let p { let i = r != 0 ? sqrt(p/r) : 0; let v = i*r; return Ohm(v: v, i: i, r: r, p: p) }
        return nil
    }

    // MARK: - Resistor color bands

    static let bandColors = ["Black","Brown","Red","Orange","Yellow","Green","Blue","Violet","Grey","White"]
    static let multiplierColors = ["Black","Brown","Red","Orange","Yellow","Green","Blue","Violet","Grey","White","Gold","Silver"]
    static let toleranceColors = ["Brown","Red","Green","Blue","Violet","Grey","Gold","Silver"]

    static func digit(_ color: String) -> Int { bandColors.firstIndex(of: color) ?? 0 }
    static func multiplier(_ color: String) -> Double {
        switch color {
        case "Gold": return 0.1
        case "Silver": return 0.01
        default: return pow(10, Double(bandColors.firstIndex(of: color) ?? 0))
        }
    }
    static func tolerance(_ color: String) -> Double {
        switch color {
        case "Brown": return 1; case "Red": return 2; case "Green": return 0.5
        case "Blue": return 0.25; case "Violet": return 0.1; case "Grey": return 0.05
        case "Gold": return 5; case "Silver": return 10; default: return 20
        }
    }

    /// Decode bands. `digits` are color names for significant figures, then a
    /// multiplier color and a tolerance color.
    static func decodeResistor(digits: [String], multiplierColor: String, toleranceColor: String) -> (ohms: Double, tol: Double) {
        var sig = 0
        for d in digits { sig = sig * 10 + digit(d) }
        let ohms = Double(sig) * multiplier(multiplierColor)
        return (ohms, tolerance(toleranceColor))
    }

    // MARK: - LED series resistor

    struct LED { var resistance: Double; var standard: Double; var power: Double; var headroom: Double }
    static func ledResistor(supply: Double, forward: Double, currentmA: Double) -> LED? {
        let i = currentmA / 1000.0
        guard i > 0, supply > forward else { return nil }
        let r = (supply - forward) / i
        let std = nearestStandard(r)
        let p = i * i * r
        return LED(resistance: r, standard: std, power: p, headroom: supply - forward)
    }

    // MARK: - Voltage divider

    static func dividerVout(vin: Double, r1: Double, r2: Double) -> Double? {
        guard r1 + r2 > 0 else { return nil }
        return vin * r2 / (r1 + r2)
    }
    /// Solve R2 for a target Vout given Vin and R1.
    static func dividerR2(vin: Double, r1: Double, vout: Double) -> Double? {
        guard vout > 0, vin > vout else { return nil }
        return r1 * vout / (vin - vout)
    }

    // MARK: - 555 astable

    struct Astable { var freq: Double; var tHigh: Double; var tLow: Double; var duty: Double }
    static func ne555Astable(r1: Double, r2: Double, c: Double) -> Astable? {
        guard r1 > 0, r2 > 0, c > 0 else { return nil }
        let tHigh = 0.693 * (r1 + r2) * c
        let tLow = 0.693 * r2 * c
        let period = tHigh + tLow
        guard period > 0 else { return nil }
        let freq = 1.0 / period
        let duty = (r1 + r2) / (r1 + 2*r2) * 100
        return Astable(freq: freq, tHigh: tHigh, tLow: tLow, duty: duty)
    }
    static func ne555Monostable(r: Double, c: Double) -> Double? {
        guard r > 0, c > 0 else { return nil }
        return 1.1 * r * c
    }

    // MARK: - RC filter

    static func rcCutoff(r: Double, c: Double) -> Double? {
        guard r > 0, c > 0 else { return nil }
        return 1.0 / (2.0 * .pi * r * c)
    }
    static func rcTau(r: Double, c: Double) -> Double? {
        guard r > 0, c > 0 else { return nil }
        return r * c
    }

    // MARK: - Battery life

    static func batteryHours(capacitymAh: Double, loadmA: Double, derate: Double = 0.85) -> Double? {
        guard loadmA > 0, capacitymAh > 0 else { return nil }
        return (capacitymAh / loadmA) * derate
    }

    /// Format a duration in seconds nicely.
    static func duration(_ seconds: Double) -> String {
        if seconds >= 3600 { return String(format: "%.2f h", seconds/3600) }
        if seconds >= 1 { return String(format: "%.3g s", seconds) }
        return eng(seconds, unit: "s")
    }
}
