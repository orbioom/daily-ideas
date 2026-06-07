import Foundation
import SwiftData

/// A rocket motor (engine). Either drawn from the built-in catalog or created by
/// the user (`isCustom`). All masses are in grams, thrust in newtons, time in
/// seconds. `delaysCSV` lists the ejection-delay options the motor ships with,
/// e.g. "0,3,5,7" seconds.
@Model
final class Motor {
    var id: UUID = UUID()
    /// e.g. "C6", "D12", "F15".
    var designation: String = ""
    var manufacturer: String = ""
    /// Total impulse in newton-seconds.
    var totalImpulseNs: Double = 0
    /// Average thrust in newtons.
    var avgThrustN: Double = 0
    /// Burn time in seconds.
    var burnTimeS: Double = 0
    /// Propellant mass in grams (mass lost during the burn).
    var propMassG: Double = 0
    /// Total loaded mass in grams (including propellant and casing).
    var totalMassG: Double = 0
    /// Casing diameter in millimetres (18, 24, 29 …).
    var diameterMm: Double = 18
    /// Comma-separated ejection delay options in seconds, e.g. "0,3,5,7".
    var delaysCSV: String = ""
    var isCustom: Bool = false

    init(
        id: UUID = UUID(),
        designation: String = "",
        manufacturer: String = "",
        totalImpulseNs: Double = 0,
        avgThrustN: Double = 0,
        burnTimeS: Double = 0,
        propMassG: Double = 0,
        totalMassG: Double = 0,
        diameterMm: Double = 18,
        delaysCSV: String = "",
        isCustom: Bool = false
    ) {
        self.id = id
        self.designation = designation
        self.manufacturer = manufacturer
        self.totalImpulseNs = totalImpulseNs
        self.avgThrustN = avgThrustN
        self.burnTimeS = burnTimeS
        self.propMassG = propMassG
        self.totalMassG = totalMassG
        self.diameterMm = diameterMm
        self.delaysCSV = delaysCSV
        self.isCustom = isCustom
    }
}

extension Motor {
    /// NAR/TRA impulse class derived from total impulse (newton-seconds).
    var impulseClass: String {
        switch totalImpulseNs {
        case ..<1.26:      return "1/2A/A"
        case 1.26..<2.5:   return "A"
        case 2.5..<5:      return "B"
        case 5..<10:       return "C"
        case 10..<20:      return "D"
        case 20..<40:      return "E"
        case 40..<80:      return "F"
        default:           return "G"
        }
    }

    /// Available ejection delays parsed from `delaysCSV`, e.g. [0, 3, 5, 7].
    var delays: [Double] {
        delaysCSV
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Full label combining designation and delays, e.g. "C6-5".
    var displayName: String {
        designation
    }
}
