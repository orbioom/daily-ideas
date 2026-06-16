import Foundation
import SwiftData

@Model
final class Application {
    @Attribute(.unique) var id: UUID
    var company: String
    var role: String
    var location: String
    var workModeRaw: String
    var statusRaw: String
    var salaryMin: Decimal?
    var salaryMax: Decimal?
    var currencyCode: String
    var sourceRaw: String
    var urlString: String
    var appliedDate: Date?
    var dateAdded: Date
    var priorityRaw: String
    var excitement: Int
    var notes: String
    var isArchived: Bool
    var followUpEnabled: Bool
    var followUpDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Interview.application)
    var interviews: [Interview]

    @Relationship(deleteRule: .cascade, inverse: \Contact.application)
    var contacts: [Contact]

    @Relationship(deleteRule: .cascade, inverse: \ActivityEvent.application)
    var events: [ActivityEvent]

    @Relationship(inverse: \Tag.applications)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        company: String,
        role: String,
        location: String = "",
        workMode: WorkMode = .remote,
        status: AppStatus = .saved,
        salaryMin: Decimal? = nil,
        salaryMax: Decimal? = nil,
        currencyCode: String = "USD",
        source: AppSource = .other,
        urlString: String = "",
        appliedDate: Date? = nil,
        dateAdded: Date = Date(),
        priority: Priority = .med,
        excitement: Int = 3,
        notes: String = "",
        isArchived: Bool = false,
        followUpEnabled: Bool = false,
        followUpDate: Date? = nil
    ) {
        self.id = id
        self.company = company
        self.role = role
        self.location = location
        self.workModeRaw = workMode.rawValue
        self.statusRaw = status.rawValue
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.currencyCode = currencyCode
        self.sourceRaw = source.rawValue
        self.urlString = urlString
        self.appliedDate = appliedDate
        self.dateAdded = dateAdded
        self.priorityRaw = priority.rawValue
        self.excitement = min(5, max(1, excitement))
        self.notes = notes
        self.isArchived = isArchived
        self.followUpEnabled = followUpEnabled
        self.followUpDate = followUpDate
        self.interviews = []
        self.contacts = []
        self.events = []
        self.tags = []
    }

    // MARK: - Typed accessors (crash-proof fallbacks)

    var status: AppStatus {
        get { AppStatus(rawValue: statusRaw) ?? .saved }
        set { statusRaw = newValue.rawValue }
    }
    var workMode: WorkMode {
        get { WorkMode(rawValue: workModeRaw) ?? .remote }
        set { workModeRaw = newValue.rawValue }
    }
    var source: AppSource {
        get { AppSource(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }
    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .med }
        set { priorityRaw = newValue.rawValue }
    }

    /// Events newest-first for the timeline.
    var sortedEvents: [ActivityEvent] {
        events.sorted { $0.date > $1.date }
    }

    var sortedInterviews: [Interview] {
        interviews.sorted { ($0.scheduledDate ?? .distantFuture) < ($1.scheduledDate ?? .distantFuture) }
    }

    /// Date the first company response was recorded, if any (used for time-to-response).
    var firstResponseDate: Date? {
        events
            .filter { $0.kind == .statusChanged && ($0.responseStatus?.indicatesResponse ?? false) }
            .map(\.date)
            .min()
    }
}
