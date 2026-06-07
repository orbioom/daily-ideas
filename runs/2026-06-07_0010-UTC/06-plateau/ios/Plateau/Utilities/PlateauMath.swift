import Foundation

enum FoodShape: String, Codable, CaseIterable, Identifiable {
    case slab, cylinder, sphere
    var id: String { rawValue }
    var label: String {
        switch self {
        case .slab: return "Slab (steak, fillet)"
        case .cylinder: return "Cylinder (roast, loin)"
        case .sphere: return "Sphere (meatball)"
        }
    }
    var short: String { rawValue.capitalized }

    /// First-term Heisler coefficients (A₁, λ₁) for the geometry, heated from all
    /// exposed faces. These are the textbook one-term transient-conduction values.
    var heisler: (a1: Double, lambda1: Double) {
        switch self {
        case .slab:     return (1.2732, 1.5708)   // infinite slab, half-thickness
        case .cylinder: return (1.6021, 2.4048)   // infinite cylinder, radius
        case .sphere:   return (2.0000, 3.1416)   // sphere, radius
        }
    }
}

enum StartState: String, Codable, CaseIterable, Identifiable {
    case frozen, fridge, cool, room
    var id: String { rawValue }
    var label: String {
        switch self {
        case .frozen: return "Frozen (−1°C)"
        case .fridge: return "Fridge (5°C)"
        case .cool:   return "Cool (12°C)"
        case .room:   return "Room (20°C)"
        }
    }
    var celsius: Double {
        switch self {
        case .frozen: return -1; case .fridge: return 5; case .cool: return 12; case .room: return 20
        }
    }
}

/// The complete time breakdown for a sous-vide cook.
struct CookPlan {
    var comeUpMinutes: Double      // time for the core to reach the bath temperature
    var pasteurizeMinutes: Double  // hold time at temperature for the log reduction
    var totalMinutes: Double
    var pasteurizes: Bool          // is pasteurization achievable at this temp?
    var note: String
}

/// Pure sous-vide engine:
/// • Come-up time via the one-term Heisler solution of the heat equation,
///   with an effective diffusivity calibrated to Baldwin's water-bath tables.
/// • Pasteurization via a D/z thermal-death-time model (Salmonella reference).
enum PlateauMath {

    /// Effective thermal diffusivity (m²/s) calibrated so a 25 mm slab from 5°C
    /// matches Baldwin's published ~100-minute heating time in a water bath.
    static let alphaEffective = 5.1e-8

    /// Reference D-value (minutes) at 60°C and z-value (°C) for Salmonella.
    static let dRef = 2.0
    static let tRefC = 60.0
    static let zValue = 5.6

    /// Come-up time in minutes for the core to reach within `withinC` of the bath.
    static func comeUpMinutes(thicknessMM: Double, shape: FoodShape,
                              bathC: Double, startC: Double, withinC: Double = 0.5) -> Double {
        guard thicknessMM > 0, bathC > startC else { return 0 }
        // Characteristic half-dimension in metres (slab is half-thickness; round
        // shapes use the radius = half the given diameter).
        let r = (thicknessMM / 2.0) / 1000.0
        let (a1, lambda1) = shape.heisler

        // Dimensionless temperature ratio at the target core temperature.
        let coreTarget = bathC - withinC
        let theta = (coreTarget - bathC) / (startC - bathC)   // 0 < θ < 1
        let ratio = theta / a1
        guard ratio > 0, ratio < 1 else { return 0 }

        let fo = -log(ratio) / (lambda1 * lambda1)            // Fourier number
        let seconds = fo * (r * r) / alphaEffective
        return seconds / 60.0
    }

    /// D-value (minutes) at a given temperature from the D/z model.
    static func dValue(at tempC: Double) -> Double {
        dRef * pow(10.0, (tRefC - tempC) / zValue)
    }

    /// Pasteurization hold (minutes) for `logReductions` at the bath temperature.
    static func pasteurizeMinutes(bathC: Double, logReductions: Double) -> Double {
        guard bathC > 0 else { return 0 }
        return logReductions * dValue(at: bathC)
    }

    /// Compose the full cook plan.
    static func plan(thicknessMM: Double, shape: FoodShape, bathC: Double,
                     startC: Double, logReductions: Double) -> CookPlan {
        let comeUp = comeUpMinutes(thicknessMM: thicknessMM, shape: shape,
                                   bathC: bathC, startC: startC)
        let pasteurize = pasteurizeMinutes(bathC: bathC, logReductions: logReductions)
        // Below ~52°C the thermal death time is so long it is not practical.
        let pasteurizes = bathC >= 52.0 && pasteurize <= 60 * 12
        let total = comeUp + (pasteurizes ? pasteurize : 0)

        let note: String
        if bathC < 52 {
            note = "Below 52°C pasteurization isn't practical — this is a cook-and-serve temperature, not a safe hold."
        } else if pasteurize > 60 * 6 {
            note = "Pasteurization at this temperature takes many hours — workable but plan ahead."
        } else if comeUp > pasteurize {
            note = "Heating dominates here — most of the time is just bringing the core up to temperature."
        } else {
            note = "A practical hold. Hold at least the total time before serving."
        }
        return CookPlan(comeUpMinutes: comeUp, pasteurizeMinutes: pasteurizes ? pasteurize : 0,
                        totalMinutes: total, pasteurizes: pasteurizes, note: note)
    }

    static func cToF(_ c: Double) -> Double { c * 9 / 5 + 32 }
    static func fToC(_ f: Double) -> Double { (f - 32) * 5 / 9 }
}

/// Temperature formatting honoring the user's unit preference.
enum TempFmt {
    static func temp(_ celsius: Double, metric: Bool) -> String {
        metric ? String(format: "%.1f°C", celsius)
               : String(format: "%.0f°F", PlateauMath.cToF(celsius))
    }
    static func tempShort(_ celsius: Double, metric: Bool) -> String {
        metric ? String(format: "%.0f°C", celsius)
               : String(format: "%.0f°F", PlateauMath.cToF(celsius))
    }
    static func duration(_ minutes: Double) -> String {
        guard minutes.isFinite, minutes >= 0 else { return "—" }
        let total = Int(minutes.rounded())
        let h = total / 60, m = total % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(m) min"
    }
}
