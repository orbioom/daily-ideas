import Foundation
import SwiftData

enum HiveKind: String, Codable, CaseIterable, Identifiable {
    case langstroth = "Langstroth", topBar = "Top-bar", warre = "Warré", nuc = "Nuc", flow = "Flow"
    var id: String { rawValue }
}

enum HiveStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active", weak = "Weak", queenless = "Queenless", dead = "Dead", sold = "Sold"
    var id: String { rawValue }
    var isLive: Bool { self == .active || self == .weak || self == .queenless }
}

/// A 1–5 rating used for several inspection observations.
enum Rating: Int, Codable, CaseIterable, Identifiable {
    case veryLow = 1, low, medium, high, veryHigh
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .veryLow: return "Very low"; case .low: return "Low"; case .medium: return "Medium"
        case .high: return "High"; case .veryHigh: return "Very high"
        }
    }
}

enum Temperament: String, Codable, CaseIterable, Identifiable {
    case calm = "Calm", normal = "Normal", defensive = "Defensive", aggressive = "Aggressive"
    var id: String { rawValue }
}

enum SpaceStatus: String, Codable, CaseIterable, Identifiable {
    case room = "Room to grow", balanced = "Balanced", crowded = "Crowded"
    var id: String { rawValue }
}

enum HarvestType: String, Codable, CaseIterable, Identifiable {
    case honey = "Honey", wax = "Wax", propolis = "Propolis", pollen = "Pollen"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .honey: return "drop.fill"; case .wax: return "square.stack.3d.up"
        case .propolis: return "shield"; case .pollen: return "circle.grid.2x2"
        }
    }
}

@Model
final class Apiary {
    var name: String
    var location: String
    var notes: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Hive.apiary)
    var hives: [Hive]

    init(name: String, location: String = "", notes: String = "", createdAt: Date = .now) {
        self.name = name; self.location = location; self.notes = notes
        self.createdAt = createdAt; self.hives = []
    }
    var liveHives: [Hive] { hives.filter { $0.status.isLive } }
}

@Model
final class Hive {
    var name: String
    var kindRaw: String
    var statusRaw: String
    var establishedDate: Date
    var queenYear: Int
    var queenMarked: Bool
    var notes: String
    var apiary: Apiary?

    @Relationship(deleteRule: .cascade, inverse: \Inspection.hive) var inspections: [Inspection]
    @Relationship(deleteRule: .cascade, inverse: \Treatment.hive) var treatments: [Treatment]
    @Relationship(deleteRule: .cascade, inverse: \Harvest.hive) var harvests: [Harvest]

    init(name: String, kind: HiveKind = .langstroth, status: HiveStatus = .active,
         establishedDate: Date = .now, queenYear: Int = Calendar.current.component(.year, from: .now),
         queenMarked: Bool = true, notes: String = "", apiary: Apiary? = nil) {
        self.name = name; self.kindRaw = kind.rawValue; self.statusRaw = status.rawValue
        self.establishedDate = establishedDate; self.queenYear = queenYear
        self.queenMarked = queenMarked; self.notes = notes; self.apiary = apiary
        self.inspections = []; self.treatments = []; self.harvests = []
    }

    var kind: HiveKind { get { HiveKind(rawValue: kindRaw) ?? .langstroth } set { kindRaw = newValue.rawValue } }
    var status: HiveStatus { get { HiveStatus(rawValue: statusRaw) ?? .active } set { statusRaw = newValue.rawValue } }

    var latestInspection: Inspection? { inspections.max { $0.date < $1.date } }
    var activeTreatments: [Treatment] { treatments.filter { !$0.completed } }
    var totalHoneyKg: Double { harvests.filter { $0.type == .honey }.reduce(0) { $0 + $1.weightKg } }
}

@Model
final class Inspection {
    var date: Date
    var queenSeen: Bool
    var eggsSeen: Bool
    var queenCells: Int
    var broodRaw: Int
    var populationRaw: Int
    var storesRaw: Int
    var temperamentRaw: String
    var spaceRaw: String
    var mitesPer300: Int          // varroa count per ~300-bee alcohol wash
    var weather: String
    var notes: String
    var hive: Hive?

    init(date: Date = .now, queenSeen: Bool = false, eggsSeen: Bool = true, queenCells: Int = 0,
         brood: Rating = .medium, population: Rating = .medium, stores: Rating = .medium,
         temperament: Temperament = .normal, space: SpaceStatus = .balanced,
         mitesPer300: Int = 0, weather: String = "", notes: String = "", hive: Hive? = nil) {
        self.date = date; self.queenSeen = queenSeen; self.eggsSeen = eggsSeen; self.queenCells = queenCells
        self.broodRaw = brood.rawValue; self.populationRaw = population.rawValue; self.storesRaw = stores.rawValue
        self.temperamentRaw = temperament.rawValue; self.spaceRaw = space.rawValue
        self.mitesPer300 = mitesPer300; self.weather = weather; self.notes = notes; self.hive = hive
    }

    var brood: Rating { Rating(rawValue: broodRaw) ?? .medium }
    var population: Rating { Rating(rawValue: populationRaw) ?? .medium }
    var stores: Rating { Rating(rawValue: storesRaw) ?? .medium }
    var temperament: Temperament { Temperament(rawValue: temperamentRaw) ?? .normal }
    var space: SpaceStatus { SpaceStatus(rawValue: spaceRaw) ?? .balanced }

    /// Mite load as a percentage (per 100 bees). >3% is the common treat threshold.
    var mitePercent: Double { Double(mitesPer300) / 3.0 }
}

@Model
final class Treatment {
    var product: String
    var reason: String
    var startDate: Date
    var durationDays: Int
    var completed: Bool
    var notes: String
    var hive: Hive?

    init(product: String, reason: String = "Varroa", startDate: Date = .now, durationDays: Int = 14,
         completed: Bool = false, notes: String = "", hive: Hive? = nil) {
        self.product = product; self.reason = reason; self.startDate = startDate
        self.durationDays = max(0, durationDays); self.completed = completed; self.notes = notes; self.hive = hive
    }

    var removeByDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }
    var daysRemaining: Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                   to: Calendar.current.startOfDay(for: removeByDate)).day ?? 0
        return days
    }
    var isOverdue: Bool { !completed && daysRemaining < 0 }
    var isDueSoon: Bool { !completed && daysRemaining >= 0 && daysRemaining <= 2 }
}

@Model
final class Harvest {
    var date: Date
    var typeRaw: String
    var weightKg: Double
    var frames: Int
    var notes: String
    var hive: Hive?

    init(date: Date = .now, type: HarvestType = .honey, weightKg: Double = 0, frames: Int = 0,
         notes: String = "", hive: Hive? = nil) {
        self.date = date; self.typeRaw = type.rawValue; self.weightKg = max(0, weightKg)
        self.frames = max(0, frames); self.notes = notes; self.hive = hive
    }
    var type: HarvestType { HarvestType(rawValue: typeRaw) ?? .honey }
}
