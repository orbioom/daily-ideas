import Foundation
import SwiftData
import SwiftUI

/// Battery chemistry. The raw value is persisted; the enum is a computed view.
/// Depth-of-discharge defaults follow common off-grid practice.
enum Chemistry: String, CaseIterable, Identifiable, Codable {
    case lifepo4
    case agm
    case floodedLead
    case gel

    var id: String { rawValue }

    /// Recommended usable depth-of-discharge for the chemistry.
    var defaultDoD: Double {
        switch self {
        case .lifepo4:    return 0.90
        case .agm:        return 0.50
        case .floodedLead: return 0.50
        case .gel:        return 0.60
        }
    }

    var label: String {
        switch self {
        case .lifepo4:     return "LiFePO4"
        case .agm:         return "AGM"
        case .floodedLead: return "Flooded Lead"
        case .gel:         return "Gel"
        }
    }

    var blurb: String {
        switch self {
        case .lifepo4:     return "Lithium iron phosphate. Deep cycling, light, long life."
        case .agm:         return "Absorbent glass mat. Sealed lead-acid, no maintenance."
        case .floodedLead: return "Classic wet cells. Cheap, heavy, shallow cycling."
        case .gel:         return "Gelled electrolyte. Sealed, tolerant of slow discharge."
        }
    }
}

@Model
final class PowerSystem {
    var id: UUID = UUID()
    var name: String = ""
    var batteryCapacityAh: Double = 100
    var systemVoltage: Int = 12
    var chemistryRaw: String = Chemistry.lifepo4.rawValue
    /// 0 means "use the chemistry default DoD".
    var dodOverride: Double = 0
    var solarWatts: Double = 0
    var peakSunHours: Double = 4.5
    var solarEfficiency: Double = 0.75
    var chargeEfficiency: Double = 0.85
    /// 0 means "no inverter / DC only".
    var inverterWatts: Double = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Load.system)
    var loads: [Load] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        batteryCapacityAh: Double = 100,
        systemVoltage: Int = 12,
        chemistry: Chemistry = .lifepo4,
        dodOverride: Double = 0,
        solarWatts: Double = 0,
        peakSunHours: Double = 4.5,
        solarEfficiency: Double = 0.75,
        chargeEfficiency: Double = 0.85,
        inverterWatts: Double = 0,
        createdAt: Date = Date(),
        loads: [Load] = []
    ) {
        self.id = id
        self.name = name
        self.batteryCapacityAh = batteryCapacityAh
        self.systemVoltage = systemVoltage
        self.chemistryRaw = chemistry.rawValue
        self.dodOverride = dodOverride
        self.solarWatts = solarWatts
        self.peakSunHours = peakSunHours
        self.solarEfficiency = solarEfficiency
        self.chargeEfficiency = chargeEfficiency
        self.inverterWatts = inverterWatts
        self.createdAt = createdAt
        self.loads = loads
    }

    var chemistry: Chemistry {
        get { Chemistry(rawValue: chemistryRaw) ?? .lifepo4 }
        set { chemistryRaw = newValue.rawValue }
    }

    /// The depth-of-discharge actually applied: override if set, else chemistry default.
    var usableDoD: Double {
        dodOverride > 0 ? min(dodOverride, 1.0) : chemistry.defaultDoD
    }
}
