import Foundation
import SwiftData

enum SeedData {
    /// Default planning checklist relative to the wedding date.
    static func seedChecklist(_ context: ModelContext, weddingDate: Date) {
        let cal = Calendar.current
        func due(monthsBefore: Int) -> Date {
            cal.date(byAdding: .month, value: -monthsBefore, to: weddingDate) ?? weddingDate
        }
        let items: [(String, BudgetCategory, Int)] = [
            ("Set the budget", .other, 12),
            ("Book the venue", .venue, 11),
            ("Hire a photographer", .photography, 9),
            ("Book caterer & tasting", .catering, 8),
            ("Send save-the-dates", .stationery, 8),
            ("Choose attire", .attire, 7),
            ("Book music / DJ / band", .music, 6),
            ("Order invitations", .stationery, 5),
            ("Arrange flowers & decor", .flowers, 4),
            ("Order the cake", .cake, 3),
            ("Send invitations", .stationery, 3),
            ("Finalize guest count & seating", .other, 1),
            ("Confirm vendors", .other, 1),
            ("Buy wedding bands", .rings, 2),
            ("Hair & makeup trial", .beauty, 2),
        ]
        for (title, cat, months) in items {
            context.insert(ChecklistTask(title: title, dueDate: due(monthsBefore: months), category: cat))
        }
        try? context.save()
    }

    static func seedSample(_ context: ModelContext) {
        // Tables
        let head = SeatingTable(name: "Head Table", capacity: 6)
        let t1 = SeatingTable(name: "Table 1", capacity: 8)
        let t2 = SeatingTable(name: "Table 2", capacity: 8)
        [head, t1, t2].forEach { context.insert($0) }

        // Guests
        let g: [(String, WeddingSide, RSVP, Int, MealChoice, SeatingTable?)] = [
            ("Alex & Sam", .both, .yes, 2, .vegetarian, head),
            ("Mom & Dad", .partnerA, .yes, 2, .chicken, head),
            ("The Patels", .partnerB, .yes, 4, .beef, t1),
            ("Jordan Lee", .partnerA, .maybe, 1, .fish, t1),
            ("Casey Wong", .partnerB, .pending, 2, .none, nil),
            ("Riley Brooks", .partnerA, .no, 1, .none, nil),
            ("The Garcias", .partnerB, .yes, 3, .chicken, t2),
            ("Taylor Kim", .both, .pending, 1, .none, nil),
        ]
        for (name, side, rsvp, size, meal, table) in g {
            let guest = Guest(name: name, side: side, rsvp: rsvp, partySize: size, meal: meal)
            guest.table = table
            context.insert(guest)
        }

        // Budget lines
        let lines: [(String, BudgetCategory, Double, Double, Double, String)] = [
            ("Reception venue", .venue, 8000, 8200, 4000, "Garden Hall"),
            ("Catering (per head)", .catering, 6000, 0, 0, "Fine Fork"),
            ("Photographer", .photography, 3000, 2800, 1000, "Studio Light"),
            ("Dress & suit", .attire, 2500, 2200, 2200, ""),
            ("Florals", .flowers, 1500, 0, 0, "Petal & Stem"),
            ("DJ", .music, 1200, 1200, 300, "DJ Vega"),
            ("Invitations", .stationery, 600, 540, 540, ""),
        ]
        for (title, cat, est, act, paid, vendor) in lines {
            context.insert(BudgetLine(title: title, category: cat, estimatedCost: est,
                                      actualCost: act, paidAmount: paid, vendor: vendor))
        }

        try? context.save()
    }
}
