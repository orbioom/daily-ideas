import Foundation
import SwiftData

/// A fasting protocol the user can pick from or customise, e.g. 16:8.
@Model
final class Plan {
    var id: UUID
    var name: String
    var fastHours: Double
    var detail: String
    var isCustom: Bool
    var order: Int

    init(id: UUID = UUID(),
         name: String,
         fastHours: Double,
         detail: String,
         isCustom: Bool = false,
         order: Int = 0) {
        self.id = id
        self.name = name
        self.fastHours = fastHours
        self.detail = detail
        self.isCustom = isCustom
        self.order = order
    }

    var eatHours: Double { max(0, 24 - fastHours) }

    /// Seed the built-in protocols once.
    static func ensureDefaults(in context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Plan>())) ?? 0
        guard existing == 0 else { return }
        let defaults: [(String, Double, String)] = [
            ("14:10", 14, "Gentle start — fast 14h, eat in 10h"),
            ("16:8", 16, "The classic — fast 16h, eat in 8h"),
            ("18:6", 18, "Lean gains — fast 18h, eat in 6h"),
            ("20:4", 20, "Warrior — one main meal in 4h"),
            ("OMAD", 23, "One meal a day — fast 23h"),
            ("36h", 36, "Monk fast — a full-day reset"),
        ]
        for (i, d) in defaults.enumerated() {
            context.insert(Plan(name: d.0, fastHours: d.1, detail: d.2, order: i))
        }
        try? context.save()
    }
}
