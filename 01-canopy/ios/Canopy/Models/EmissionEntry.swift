import Foundation
import SwiftData

@Model
final class EmissionEntry {
    var id: UUID
    var date: Date
    var category: EmissionCategory
    var activityKey: String
    var amount: Double
    var co2eKg: Double
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        category: EmissionCategory,
        activityKey: String,
        amount: Double,
        co2eKg: Double,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.category = category
        self.activityKey = activityKey
        self.amount = amount
        self.co2eKg = co2eKg
        self.notes = notes
    }

    var activityName: String {
        EmissionsEngine.activity(for: activityKey)?.name ?? activityKey
    }

    var activityUnit: String {
        EmissionsEngine.activity(for: activityKey)?.unit ?? ""
    }
}
