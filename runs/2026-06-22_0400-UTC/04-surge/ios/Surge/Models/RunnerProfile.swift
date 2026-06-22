import Foundation
import SwiftData

@Model
final class RunnerProfile {
    var id: UUID
    var name: String
    var goalRace: String          // "marathon" or "halfMarathon"
    var goalTimeSeconds: Int      // target finish time in seconds
    var trainingStartDate: Date
    var raceDateTarget: Date?
    var weeklyBaseMileageKm: Double
    var unit: String              // "km" or "mi"
    var hasCompletedOnboarding: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        goalRace: String = "marathon",
        goalTimeSeconds: Int = 14400, // 4 hours default
        trainingStartDate: Date = Date(),
        raceDateTarget: Date? = nil,
        weeklyBaseMileageKm: Double = 25.0,
        unit: String = "km",
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.name = name
        self.goalRace = goalRace
        self.goalTimeSeconds = goalTimeSeconds
        self.trainingStartDate = trainingStartDate
        self.raceDateTarget = raceDateTarget
        self.weeklyBaseMileageKm = weeklyBaseMileageKm
        self.unit = unit
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    var raceType: RaceType {
        goalRace == "halfMarathon" ? .halfMarathon : .marathon
    }

    var totalWeeks: Int {
        raceType == .marathon ? 16 : 12
    }

    var currentWeekNumber: Int {
        let calendar = Calendar.current
        let startOfTraining = calendar.startOfDay(for: trainingStartDate)
        let today = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: startOfTraining, to: today).day ?? 0
        return max(1, min(totalWeeks, (days / 7) + 1))
    }

    var daysUntilRace: Int? {
        guard let raceDate = raceDateTarget else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let race = calendar.startOfDay(for: raceDate)
        return calendar.dateComponents([.day], from: today, to: race).day
    }
}

enum RaceType: String, CaseIterable {
    case marathon = "marathon"
    case halfMarathon = "halfMarathon"

    var displayName: String {
        switch self {
        case .marathon: return "Marathon"
        case .halfMarathon: return "Half Marathon"
        }
    }

    var distanceKm: Double {
        switch self {
        case .marathon: return 42.195
        case .halfMarathon: return 21.0975
        }
    }

    var totalWeeks: Int {
        switch self {
        case .marathon: return 16
        case .halfMarathon: return 12
        }
    }
}
