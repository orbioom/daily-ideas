import Foundation
import SwiftData

@Model
final class EliminationPhase {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var phaseType: String
    var foodsToAvoid: [String]
    var foodBeingChallenged: String?
    var notes: String
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        phaseType: String = "eliminate",
        foodsToAvoid: [String] = [],
        foodBeingChallenged: String? = nil,
        notes: String = "",
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.phaseType = phaseType
        self.foodsToAvoid = foodsToAvoid
        self.foodBeingChallenged = foodBeingChallenged
        self.notes = notes
        self.isActive = isActive
    }
}

// MARK: - PhaseType

enum PhaseType: String, CaseIterable {
    case eliminate = "eliminate"
    case challenge = "challenge"
    case rest = "rest"
    case maintenance = "maintenance"

    var displayName: String {
        switch self {
        case .eliminate: return "Elimination"
        case .challenge: return "Challenge"
        case .rest: return "Rest"
        case .maintenance: return "Maintenance"
        }
    }

    var icon: String {
        switch self {
        case .eliminate: return "minus.circle.fill"
        case .challenge: return "flask.fill"
        case .rest: return "moon.fill"
        case .maintenance: return "checkmark.seal.fill"
        }
    }

    var defaultDays: Int {
        switch self {
        case .eliminate: return 21
        case .challenge: return 3
        case .rest: return 3
        case .maintenance: return 0
        }
    }
}

// MARK: - Computed helpers

extension EliminationPhase {
    var computedEndDate: Date {
        if let endDate = endDate { return endDate }
        let days = PhaseType(rawValue: phaseType)?.defaultDays ?? 7
        return Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
    }

    var daysElapsed: Int {
        let now = Date()
        return Calendar.current.dateComponents([.day], from: startDate, to: now).day ?? 0
    }

    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: computedEndDate).day ?? 1
    }

    var progress: Double {
        guard totalDays > 0 else { return 1.0 }
        return min(1.0, max(0.0, Double(daysElapsed) / Double(totalDays)))
    }

    var isCompleted: Bool {
        Date() >= computedEndDate
    }

    var statusLabel: String {
        if isCompleted { return "Completed" }
        if isActive { return "In Progress" }
        return "Upcoming"
    }

    var daysRemainingLabel: String {
        if isCompleted { return "Done" }
        let remaining = totalDays - daysElapsed
        return remaining == 1 ? "1 day left" : "\(remaining) days left"
    }
}
