import SwiftData
import Foundation

enum ChargerType: String, CaseIterable, Codable {
    case l1 = "Level 1"
    case l2 = "Level 2"
    case dcFast = "DC Fast"
    case supercharger = "Supercharger"
    case chademo = "CHAdeMO"

    var icon: String {
        switch self {
        case .l1: return "plug"
        case .l2: return "bolt.fill"
        case .dcFast: return "bolt.batteryblock.fill"
        case .supercharger: return "bolt.circle.fill"
        case .chademo: return "cable.connector"
        }
    }

    var speedLabel: String {
        switch self {
        case .l1: return "~1.4 kW"
        case .l2: return "~7–22 kW"
        case .dcFast: return "~50–150 kW"
        case .supercharger: return "~150–250 kW"
        case .chademo: return "~50 kW"
        }
    }
}

@Model
final class ChargingSession {
    var id: UUID
    var date: Date
    var kwhAdded: Double
    var cost: Double
    var startSoC: Double
    var endSoC: Double
    var chargerTypeRaw: String
    var locationName: String
    var durationMinutes: Double
    var odometer: Double
    var notes: String

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        kwhAdded: Double,
        cost: Double,
        startSoC: Double = 0,
        endSoC: Double = 0,
        chargerType: ChargerType = .l2,
        locationName: String = "",
        durationMinutes: Double = 0,
        odometer: Double = 0,
        notes: String = "",
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.kwhAdded = kwhAdded
        self.cost = cost
        self.startSoC = startSoC
        self.endSoC = endSoC
        self.chargerTypeRaw = chargerType.rawValue
        self.locationName = locationName
        self.durationMinutes = durationMinutes
        self.odometer = odometer
        self.notes = notes
        self.vehicle = vehicle
    }

    var chargerType: ChargerType {
        get { ChargerType(rawValue: chargerTypeRaw) ?? .l2 }
        set { chargerTypeRaw = newValue.rawValue }
    }

    var costPerKWh: Double {
        guard kwhAdded > 0 else { return 0 }
        return cost / kwhAdded
    }

    var chargeAdded: Double { endSoC - startSoC }
}
