import Foundation
import SwiftData
import SwiftUI

enum Stage: String, CaseIterable, Codable, Identifiable {
    case wishlist, applied, screening, interview, offer, accepted, rejected, ghosted, withdrawn

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wishlist: return "Wishlist"
        case .applied: return "Applied"
        case .screening: return "Screening"
        case .interview: return "Interview"
        case .offer: return "Offer"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .ghosted: return "Ghosted"
        case .withdrawn: return "Withdrawn"
        }
    }

    /// Funnel depth used for conversion math. Closed stages return the depth reached separately.
    var funnelDepth: Int? {
        switch self {
        case .applied: return 0
        case .screening: return 1
        case .interview: return 2
        case .offer, .accepted: return 3
        case .wishlist, .rejected, .ghosted, .withdrawn: return nil
        }
    }

    var isClosed: Bool {
        switch self {
        case .accepted, .rejected, .ghosted, .withdrawn: return true
        default: return false
        }
    }

    var icon: String {
        switch self {
        case .wishlist: return "star"
        case .applied: return "paperplane.fill"
        case .screening: return "phone.fill"
        case .interview: return "person.2.fill"
        case .offer: return "envelope.open.fill"
        case .accepted: return "checkmark.seal.fill"
        case .rejected: return "xmark.circle.fill"
        case .ghosted: return "moon.fill"
        case .withdrawn: return "arrow.uturn.left"
        }
    }
}

enum WorkMode: String, CaseIterable, Codable {
    case onsite, hybrid, remote
    var label: String { rawValue.capitalized }
}

@Model
final class Application {
    var company: String
    var role: String
    var location: String
    var workModeRaw: String
    var salaryText: String
    var link: String
    /// 1–5 how excited you are about this one.
    var excitement: Int
    var appliedDate: Date?
    var createdAt: Date
    var stageRaw: String
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \StageEvent.application)
    var events: [StageEvent]
    @Relationship(deleteRule: .cascade, inverse: \Interview.application)
    var interviews: [Interview]
    @Relationship(deleteRule: .cascade, inverse: \JobContact.application)
    var contacts: [JobContact]
    @Relationship(deleteRule: .cascade, inverse: \FollowUp.application)
    var followUps: [FollowUp]

    init(company: String, role: String, location: String = "", workMode: WorkMode = .hybrid,
         salaryText: String = "", link: String = "", excitement: Int = 3,
         appliedDate: Date? = nil, stage: Stage = .wishlist, notes: String = "") {
        self.company = company
        self.role = role
        self.location = location
        self.workModeRaw = workMode.rawValue
        self.salaryText = salaryText
        self.link = link
        self.excitement = excitement
        self.appliedDate = appliedDate
        self.createdAt = Date()
        self.stageRaw = stage.rawValue
        self.notes = notes
        self.events = []
        self.interviews = []
        self.contacts = []
        self.followUps = []
    }

    var stage: Stage { Stage(rawValue: stageRaw) ?? .wishlist }
    var workMode: WorkMode { WorkMode(rawValue: workModeRaw) ?? .hybrid }

    /// Deepest funnel stage this application ever reached (events + current).
    var maxDepthReached: Int? {
        var depths: [Int] = []
        if let d = stage.funnelDepth { depths.append(d) }
        for e in events {
            if let d = e.stage.funnelDepth { depths.append(d) }
        }
        return depths.max()
    }

    var lastActivity: Date {
        var dates = [createdAt]
        if let a = appliedDate { dates.append(a) }
        dates.append(contentsOf: events.map(\.date))
        return dates.max() ?? createdAt
    }
}

@Model
final class StageEvent {
    var date: Date
    var stageRaw: String
    var note: String
    var application: Application?

    init(date: Date = Date(), stage: Stage, note: String = "") {
        self.date = date
        self.stageRaw = stage.rawValue
        self.note = note
    }

    var stage: Stage { Stage(rawValue: stageRaw) ?? .applied }
}

enum InterviewKind: String, CaseIterable, Codable {
    case phone, technical, onsite, panel, final
    var label: String {
        switch self {
        case .phone: return "Phone screen"
        case .technical: return "Technical"
        case .onsite: return "Onsite"
        case .panel: return "Panel"
        case .final: return "Final round"
        }
    }
}

enum InterviewOutcome: String, CaseIterable, Codable {
    case pending, passed, failed
    var label: String { rawValue.capitalized }
}

@Model
final class Interview {
    var kindRaw: String
    var scheduledAt: Date
    var notes: String
    var outcomeRaw: String
    var application: Application?

    init(kind: InterviewKind, scheduledAt: Date, notes: String = "",
         outcome: InterviewOutcome = .pending) {
        self.kindRaw = kind.rawValue
        self.scheduledAt = scheduledAt
        self.notes = notes
        self.outcomeRaw = outcome.rawValue
    }

    var kind: InterviewKind { InterviewKind(rawValue: kindRaw) ?? .phone }
    var outcome: InterviewOutcome { InterviewOutcome(rawValue: outcomeRaw) ?? .pending }
}

@Model
final class JobContact {
    var name: String
    var title: String
    var email: String
    var notes: String
    var application: Application?

    init(name: String, title: String = "", email: String = "", notes: String = "") {
        self.name = name
        self.title = title
        self.email = email
        self.notes = notes
    }
}

@Model
final class FollowUp {
    var title: String
    var dueDate: Date
    var isDone: Bool
    var application: Application?

    init(title: String, dueDate: Date, isDone: Bool = false) {
        self.title = title
        self.dueDate = dueDate
        self.isDone = isDone
    }
}
