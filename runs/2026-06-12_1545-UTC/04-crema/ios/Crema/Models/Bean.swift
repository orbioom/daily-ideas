import Foundation
import SwiftData
import SwiftUI

enum RoastLevel: String, Codable, CaseIterable, Identifiable {
    case light = "Light", mediumLight = "Medium-Light", medium = "Medium"
    case mediumDark = "Medium-Dark", dark = "Dark"
    var id: String { rawValue }
}

enum ProcessMethod: String, Codable, CaseIterable, Identifiable {
    case washed = "Washed", natural = "Natural", honey = "Honey"
    case anaerobic = "Anaerobic", other = "Other"
    var id: String { rawValue }
}

@Model
final class Bean {
    @Attribute(.unique) var id: UUID
    var name: String
    var roaster: String
    var origin: String
    var roastLevelRaw: String
    var processRaw: String
    var roastDate: Date?
    var pricePaid: Double
    var bagSizeGrams: Double          // total bag weight
    var gramsUsed: Double             // tracked as brews log dose
    var isArchived: Bool
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Brew.bean)
    var brews: [Brew] = []

    init(name: String, roaster: String = "", origin: String = "",
         roastLevel: RoastLevel = .medium, process: ProcessMethod = .washed,
         roastDate: Date? = nil, pricePaid: Double = 0, bagSizeGrams: Double = 250,
         notes: String = "") {
        self.id = UUID()
        self.name = name
        self.roaster = roaster
        self.origin = origin
        self.roastLevelRaw = roastLevel.rawValue
        self.processRaw = process.rawValue
        self.roastDate = roastDate
        self.pricePaid = pricePaid
        self.bagSizeGrams = bagSizeGrams
        self.gramsUsed = 0
        self.isArchived = false
        self.notes = notes
        self.createdAt = Date()
    }

    var roastLevel: RoastLevel {
        get { RoastLevel(rawValue: roastLevelRaw) ?? .medium }
        set { roastLevelRaw = newValue.rawValue }
    }
    var process: ProcessMethod {
        get { ProcessMethod(rawValue: processRaw) ?? .washed }
        set { processRaw = newValue.rawValue }
    }

    var gramsRemaining: Double { max(bagSizeGrams - gramsUsed, 0) }

    var daysSinceRoast: Int? {
        guard let roastDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: roastDate),
                                               to: Calendar.current.startOfDay(for: Date())).day
    }

    var bestBrew: Brew? { brews.filter { $0.ratingHalf > 0 }.max { $0.ratingHalf < $1.ratingHalf } }
}
