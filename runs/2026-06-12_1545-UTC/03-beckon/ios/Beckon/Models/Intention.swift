import Foundation
import SwiftData
import SwiftUI

enum IntentionCategory: String, Codable, CaseIterable, Identifiable {
    case love = "Love", wealth = "Wealth", health = "Health", career = "Career"
    case growth = "Growth", peace = "Peace", custom = "Custom"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .love: return "heart.fill"
        case .wealth: return "sparkles"
        case .health: return "leaf.fill"
        case .career: return "briefcase.fill"
        case .growth: return "arrow.up.forward.circle.fill"
        case .peace: return "moon.stars.fill"
        case .custom: return "star.fill"
        }
    }
    var hue: Double {
        switch self {
        case .love: return 0.96
        case .wealth: return 0.13
        case .health: return 0.38
        case .career: return 0.58
        case .growth: return 0.78
        case .peace: return 0.68
        case .custom: return 0.08
        }
    }
}

enum IntentionState: String, Codable {
    case active, manifested, released
}

/// The phases of the 369 ritual: write 3 in the morning, 6 in the afternoon,
/// 9 at night.
enum Phase: String, CaseIterable, Identifiable {
    case morning, afternoon, evening
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var target: Int {
        switch self { case .morning: return 3; case .afternoon: return 6; case .evening: return 9 }
    }
    var symbol: String {
        switch self { case .morning: return "sunrise.fill"; case .afternoon: return "sun.max.fill"; case .evening: return "moon.stars.fill" }
    }
    /// The phase most appropriate to the current hour.
    static func recommended(for date: Date = Date(), calendar: Calendar = .current) -> Phase {
        let h = calendar.component(.hour, from: date)
        if h < 12 { return .morning }
        if h < 18 { return .afternoon }
        return .evening
    }
}

@Model
final class Intention {
    @Attribute(.unique) var id: UUID
    var title: String
    /// The affirmation, written in the present tense (what the user repeats).
    var affirmation: String
    var categoryRaw: String
    var stateRaw: String
    var practiceLength: Int          // 33 or 45 days, classic 369 cycles
    var createdAt: Date
    var manifestedAt: Date?
    var notes: String                // free "scripting" space

    @Relationship(deleteRule: .cascade, inverse: \PracticeLog.intention)
    var logs: [PracticeLog] = []

    init(title: String, affirmation: String, category: IntentionCategory = .growth,
         practiceLength: Int = 33, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.affirmation = affirmation
        self.categoryRaw = category.rawValue
        self.stateRaw = IntentionState.active.rawValue
        self.practiceLength = practiceLength
        self.createdAt = Date()
        self.notes = notes
    }

    var category: IntentionCategory {
        get { IntentionCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
    var state: IntentionState {
        get { IntentionState(rawValue: stateRaw) ?? .active }
        set { stateRaw = newValue.rawValue }
    }
    var tint: Color { Color(hue: category.hue, saturation: 0.55, brightness: 0.80) }

    func log(for day: Date, calendar: Calendar = .current) -> PracticeLog? {
        let key = calendar.startOfDay(for: day)
        return logs.first { calendar.isDate($0.day, inSameDayAs: key) }
    }

    /// Number of fully-completed practice days.
    var completedDays: Int { logs.filter(\.isComplete).count }
    var cycleProgress: Double {
        guard practiceLength > 0 else { return 0 }
        return min(Double(completedDays) / Double(practiceLength), 1)
    }
}

@Model
final class PracticeLog {
    var day: Date                    // start-of-day
    var morning: Int
    var afternoon: Int
    var evening: Int
    var intention: Intention?

    init(day: Date, morning: Int = 0, afternoon: Int = 0, evening: Int = 0) {
        self.day = Calendar.current.startOfDay(for: day)
        self.morning = morning
        self.afternoon = afternoon
        self.evening = evening
    }

    func count(for phase: Phase) -> Int {
        switch phase { case .morning: return morning; case .afternoon: return afternoon; case .evening: return evening }
    }
    func set(_ value: Int, for phase: Phase) {
        switch phase {
        case .morning: morning = value
        case .afternoon: afternoon = value
        case .evening: evening = value
        }
    }
    var totalReps: Int { morning + afternoon + evening }
    var isComplete: Bool { morning >= 3 && afternoon >= 6 && evening >= 9 }
    func isPhaseComplete(_ phase: Phase) -> Bool { count(for: phase) >= phase.target }
}
