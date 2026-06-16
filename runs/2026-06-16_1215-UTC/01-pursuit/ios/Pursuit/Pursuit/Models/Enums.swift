import SwiftUI

// MARK: - Application Status

enum AppStatus: String, CaseIterable, Identifiable, Codable {
    case saved, applied, screening, interview, offer, accepted, rejected, withdrawn

    var id: String { rawValue }

    var label: String {
        switch self {
        case .saved: return "Saved"
        case .applied: return "Applied"
        case .screening: return "Screening"
        case .interview: return "Interview"
        case .offer: return "Offer"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .withdrawn: return "Withdrawn"
        }
    }

    var symbol: String {
        switch self {
        case .saved: return "bookmark.fill"
        case .applied: return "paperplane.fill"
        case .screening: return "phone.fill"
        case .interview: return "person.2.fill"
        case .offer: return "envelope.open.fill"
        case .accepted: return "checkmark.seal.fill"
        case .rejected: return "xmark.circle.fill"
        case .withdrawn: return "arrow.uturn.backward.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .saved: return Color.dyn(0x8A8FA6, 0x9AA0BC)
        case .applied: return Theme.info
        case .screening: return Color.dyn(0x2C9CB0, 0x49C2D6)
        case .interview: return Color.dyn(0x7A5BD4, 0x9A7EF0)
        case .offer: return Theme.warn
        case .accepted: return Theme.good
        case .rejected: return Theme.bad
        case .withdrawn: return Color.dyn(0x9094AB, 0x6A6E86)
        }
    }

    /// Active funnel stages displayed in the pipeline, in order.
    static var pipelineOrder: [AppStatus] {
        [.saved, .applied, .screening, .interview, .offer, .accepted, .rejected, .withdrawn]
    }

    /// Ordered conversion funnel stages (excludes terminal negative states).
    static var funnelStages: [AppStatus] {
        [.applied, .screening, .interview, .offer, .accepted]
    }

    /// True once the application has actually been submitted (counts toward "applied+").
    var isSubmitted: Bool {
        switch self {
        case .saved: return false
        default: return true
        }
    }

    /// True if the company has responded beyond the initial application.
    var indicatesResponse: Bool {
        switch self {
        case .screening, .interview, .offer, .accepted, .rejected: return true
        default: return false
        }
    }

    var reachedInterview: Bool {
        switch self {
        case .interview, .offer, .accepted: return true
        default: return false
        }
    }

    var reachedOffer: Bool {
        switch self {
        case .offer, .accepted: return true
        default: return false
        }
    }

    var isTerminal: Bool {
        switch self {
        case .accepted, .rejected, .withdrawn: return true
        default: return false
        }
    }

    /// The natural "advance" target when swiping forward, if any.
    var next: AppStatus? {
        switch self {
        case .saved: return .applied
        case .applied: return .screening
        case .screening: return .interview
        case .interview: return .offer
        case .offer: return .accepted
        default: return nil
        }
    }
}

// MARK: - Work Mode

enum WorkMode: String, CaseIterable, Identifiable, Codable {
    case remote, hybrid, onsite
    var id: String { rawValue }
    var label: String {
        switch self {
        case .remote: return "Remote"
        case .hybrid: return "Hybrid"
        case .onsite: return "On-site"
        }
    }
    var symbol: String {
        switch self {
        case .remote: return "house.fill"
        case .hybrid: return "arrow.left.arrow.right"
        case .onsite: return "building.2.fill"
        }
    }
}

// MARK: - Source

enum AppSource: String, CaseIterable, Identifiable, Codable {
    case linkedIn = "LinkedIn"
    case indeed = "Indeed"
    case referral = "Referral"
    case companySite = "CompanySite"
    case recruiter = "Recruiter"
    case other = "Other"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .companySite: return "Company Site"
        default: return rawValue
        }
    }
    var symbol: String {
        switch self {
        case .linkedIn: return "link"
        case .indeed: return "magnifyingglass"
        case .referral: return "person.crop.circle.badge.checkmark"
        case .companySite: return "globe"
        case .recruiter: return "person.text.rectangle"
        case .other: return "ellipsis.circle"
        }
    }
    var color: Color {
        switch self {
        case .linkedIn: return Theme.info
        case .indeed: return Color.dyn(0x3A5BC9, 0x6E8BE8)
        case .referral: return Theme.good
        case .companySite: return Theme.accent
        case .recruiter: return Color.dyn(0x9A6BD4, 0xB28EF0)
        case .other: return Theme.inkSoft
        }
    }
}

// MARK: - Priority

enum Priority: String, CaseIterable, Identifiable, Codable {
    case low, med, high
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Low"
        case .med: return "Medium"
        case .high: return "High"
        }
    }
    var symbol: String {
        switch self {
        case .low: return "flag"
        case .med: return "flag.fill"
        case .high: return "flag.2.crossed.fill"
        }
    }
    var color: Color {
        switch self {
        case .low: return Theme.inkSoft
        case .med: return Theme.info
        case .high: return Theme.bad
        }
    }
    var sortRank: Int {
        switch self {
        case .high: return 0
        case .med: return 1
        case .low: return 2
        }
    }
}

// MARK: - Interview Mode & Outcome

enum InterviewMode: String, CaseIterable, Identifiable, Codable {
    case phone, video, onsite, take_home = "Take-home"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .phone: return "Phone"
        case .video: return "Video"
        case .onsite: return "On-site"
        case .take_home: return "Take-home"
        }
    }
    var symbol: String {
        switch self {
        case .phone: return "phone.fill"
        case .video: return "video.fill"
        case .onsite: return "building.2.fill"
        case .take_home: return "laptopcomputer"
        }
    }
}

enum InterviewOutcome: String, CaseIterable, Identifiable, Codable {
    case pending, passed, failed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .pending: return "Pending"
        case .passed: return "Passed"
        case .failed: return "Did not advance"
        }
    }
    var symbol: String {
        switch self {
        case .pending: return "clock.fill"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .pending: return Theme.warn
        case .passed: return Theme.good
        case .failed: return Theme.bad
        }
    }
}

// MARK: - Contact Role

enum ContactRole: String, CaseIterable, Identifiable, Codable {
    case recruiter, hiringManager, referral, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .recruiter: return "Recruiter"
        case .hiringManager: return "Hiring Manager"
        case .referral: return "Referral"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .recruiter: return "person.text.rectangle"
        case .hiringManager: return "person.badge.key.fill"
        case .referral: return "person.crop.circle.badge.checkmark"
        case .other: return "person.fill"
        }
    }
}

// MARK: - Activity Event Kind

enum ActivityKind: String, CaseIterable, Identifiable, Codable {
    case created, statusChanged, note, interviewScheduled, followUp
    var id: String { rawValue }
    var label: String {
        switch self {
        case .created: return "Created"
        case .statusChanged: return "Status changed"
        case .note: return "Note"
        case .interviewScheduled: return "Interview scheduled"
        case .followUp: return "Follow-up"
        }
    }
    var symbol: String {
        switch self {
        case .created: return "sparkles"
        case .statusChanged: return "arrow.triangle.swap"
        case .note: return "note.text"
        case .interviewScheduled: return "calendar.badge.plus"
        case .followUp: return "bell.fill"
        }
    }
    var color: Color {
        switch self {
        case .created: return Theme.accent
        case .statusChanged: return Theme.info
        case .note: return Theme.inkSoft
        case .interviewScheduled: return Color.dyn(0x7A5BD4, 0x9A7EF0)
        case .followUp: return Theme.warn
        }
    }
}
