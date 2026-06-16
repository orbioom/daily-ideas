import Foundation
import SwiftData

@Model
final class ActivityEvent {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var date: Date
    var detail: String
    /// For statusChanged events, the status that was moved into (raw value).
    var statusRaw: String?

    var application: Application?

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        date: Date = Date(),
        detail: String,
        status: AppStatus? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.date = date
        self.detail = detail
        self.statusRaw = status?.rawValue
    }

    var kind: ActivityKind {
        get { ActivityKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    /// Resolved status for statusChanged events.
    var responseStatus: AppStatus? {
        guard let raw = statusRaw else { return nil }
        return AppStatus(rawValue: raw)
    }
}
