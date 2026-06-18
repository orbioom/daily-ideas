import Foundation
import SwiftData

/// Learning status for a trick. Stored as a raw string for SwiftData friendliness.
enum TrickStatus: String, CaseIterable, Identifiable {
    case notStarted = "Not Started"
    case learning = "Learning"
    case practicing = "Practicing"
    case mastered = "Mastered"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .learning: return "book.fill"
        case .practicing: return "figure.run"
        case .mastered: return "checkmark.seal.fill"
        }
    }

    /// Ordering value for progress math.
    var rank: Int {
        switch self {
        case .notStarted: return 0
        case .learning: return 1
        case .practicing: return 2
        case .mastered: return 3
        }
    }
}

@Model
final class TrickProgress {
    @Attribute(.unique) var id: UUID
    var dog: Dog?
    var trickId: String
    var statusRaw: String
    var sessionCount: Int
    var lastPracticed: Date?
    var updatedAt: Date

    var status: TrickStatus {
        get { TrickStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        dog: Dog? = nil,
        trickId: String,
        status: TrickStatus = .notStarted,
        sessionCount: Int = 0,
        lastPracticed: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dog = dog
        self.trickId = trickId
        self.statusRaw = status.rawValue
        self.sessionCount = sessionCount
        self.lastPracticed = lastPracticed
        self.updatedAt = updatedAt
    }
}
