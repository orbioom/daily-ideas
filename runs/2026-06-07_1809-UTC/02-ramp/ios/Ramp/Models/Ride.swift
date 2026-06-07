import Foundation
import SwiftData

/// The kind of training a ride represents. Stored as a String rawValue.
enum RideType: String, CaseIterable, Identifiable {
    case recovery, endurance, tempo, threshold, vo2, race, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .recovery:  return "Recovery"
        case .endurance: return "Endurance"
        case .tempo:     return "Tempo"
        case .threshold: return "Threshold"
        case .vo2:       return "VO2 Max"
        case .race:      return "Race"
        case .other:     return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .recovery:  return "leaf"
        case .endurance: return "road.lanes"
        case .tempo:     return "speedometer"
        case .threshold: return "bolt.heart"
        case .vo2:       return "flame"
        case .race:      return "flag.checkered"
        case .other:     return "bicycle"
        }
    }
}

/// How the ride's stress was sourced.
enum EntryMode: String, CaseIterable, Identifiable {
    case power, manual
    var id: String { rawValue }
    var label: String { self == .power ? "Power" : "Manual" }
}

@Model
final class Ride {
    var id: UUID = UUID()
    var date: Date = Date()
    var name: String = ""
    var durationMin: Int = 0
    var typeRaw: String = RideType.endurance.rawValue
    var entryRaw: String = EntryMode.power.rawValue
    var normalizedPower: Int = 0
    var ftpAtTime: Int = 0
    var tssManual: Double = 0
    var distanceKm: Double = 0
    var notes: String = ""

    init(id: UUID = UUID(),
         date: Date = Date(),
         name: String = "",
         durationMin: Int = 0,
         type: RideType = .endurance,
         entry: EntryMode = .power,
         normalizedPower: Int = 0,
         ftpAtTime: Int = 0,
         tssManual: Double = 0,
         distanceKm: Double = 0,
         notes: String = "") {
        self.id = id
        self.date = date
        self.name = name
        self.durationMin = durationMin
        self.typeRaw = type.rawValue
        self.entryRaw = entry.rawValue
        self.normalizedPower = normalizedPower
        self.ftpAtTime = ftpAtTime
        self.tssManual = tssManual
        self.distanceKm = distanceKm
        self.notes = notes
    }

    var type: RideType {
        get { RideType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var entry: EntryMode {
        get { EntryMode(rawValue: entryRaw) ?? .power }
        set { entryRaw = newValue.rawValue }
    }

    /// Intensity Factor — NP / FTP. Zero when FTP is unknown or in manual mode.
    var intensityFactor: Double {
        guard entry == .power, ftpAtTime > 0 else { return 0 }
        return Double(normalizedPower) / Double(ftpAtTime)
    }

    /// Training Stress Score for this ride.
    var tss: Double {
        switch entry {
        case .manual:
            return max(0, tssManual)
        case .power:
            guard ftpAtTime > 0, durationMin > 0 else { return 0 }
            let ifv = intensityFactor
            return (Double(durationMin) / 60.0) * ifv * ifv * 100.0
        }
    }
}
