import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: UInt32
    var billable: Bool
    var useCustomRate: Bool
    var customRate: Double
    var archived: Bool
    var createdAt: Date
    var client: Client?

    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.project)
    var entries: [TimeEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: UInt32 = 0x3E8E7E,
        billable: Bool = true,
        useCustomRate: Bool = false,
        customRate: Double = 0,
        archived: Bool = false,
        createdAt: Date = .now,
        client: Client? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.billable = billable
        self.useCustomRate = useCustomRate
        self.customRate = max(0, customRate)
        self.archived = archived
        self.createdAt = createdAt
        self.client = client
    }

    /// Effective hourly rate: the project's own rate if set, else the client's.
    var effectiveRate: Double {
        if useCustomRate { return customRate }
        return client?.hourlyRate ?? 0
    }
}
