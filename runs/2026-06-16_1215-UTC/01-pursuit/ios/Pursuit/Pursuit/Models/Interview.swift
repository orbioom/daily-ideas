import Foundation
import SwiftData

@Model
final class Interview {
    @Attribute(.unique) var id: UUID
    var roundName: String
    var scheduledDate: Date?
    var durationMin: Int
    var modeRaw: String
    var interviewers: String
    var prepNotes: String
    var notes: String
    var outcomeRaw: String

    var application: Application?

    init(
        id: UUID = UUID(),
        roundName: String,
        scheduledDate: Date? = nil,
        durationMin: Int = 45,
        mode: InterviewMode = .video,
        interviewers: String = "",
        prepNotes: String = "",
        notes: String = "",
        outcome: InterviewOutcome = .pending
    ) {
        self.id = id
        self.roundName = roundName
        self.scheduledDate = scheduledDate
        self.durationMin = max(0, durationMin)
        self.modeRaw = mode.rawValue
        self.interviewers = interviewers
        self.prepNotes = prepNotes
        self.notes = notes
        self.outcomeRaw = outcome.rawValue
    }

    var mode: InterviewMode {
        get { InterviewMode(rawValue: modeRaw) ?? .video }
        set { modeRaw = newValue.rawValue }
    }
    var outcome: InterviewOutcome {
        get { InterviewOutcome(rawValue: outcomeRaw) ?? .pending }
        set { outcomeRaw = newValue.rawValue }
    }

    var isUpcoming: Bool {
        guard let date = scheduledDate else { return false }
        return date >= Calendar.current.startOfDay(for: Date()) && outcome == .pending
    }
}
