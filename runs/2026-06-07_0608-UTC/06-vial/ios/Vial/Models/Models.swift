import Foundation
import SwiftData

/// A medication with a dosing schedule and an on-hand supply count.
@Model
final class Medication {
    var id: UUID = UUID()
    var name: String = ""
    var strength: String = ""          // e.g. "10 mg"
    var form: String = "Tablet"        // Tablet / Capsule / Liquid / Drop / Unit
    /// Times of day to take a dose, as minutes from midnight.
    var doseTimes: [Int] = [480]       // default 8:00
    /// Weekdays the schedule applies to (1=Sun…7=Sat). Empty = every day.
    var weekdays: [Int] = []
    /// Units consumed per scheduled dose (e.g. 1 tablet, 2 capsules).
    var unitsPerDose: Double = 1
    /// Units currently on hand.
    var quantityOnHand: Double = 0
    /// Days before run-out to flag a refill.
    var refillThresholdDays: Int = 7
    var colorHex: UInt32 = 0x5EB7F0
    var notes: String = ""
    var isActive: Bool = true
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \DoseLog.medication)
    var logs: [DoseLog] = []
    @Relationship(deleteRule: .cascade, inverse: \Refill.medication)
    var refills: [Refill] = []

    init(name: String, strength: String = "", form: String = "Tablet",
         doseTimes: [Int] = [480], weekdays: [Int] = [], unitsPerDose: Double = 1,
         quantityOnHand: Double = 0, refillThresholdDays: Int = 7,
         colorHex: UInt32 = 0x5EB7F0, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.strength = strength
        self.form = form
        self.doseTimes = doseTimes
        self.weekdays = weekdays
        self.unitsPerDose = unitsPerDose
        self.quantityOnHand = quantityOnHand
        self.refillThresholdDays = refillThresholdDays
        self.colorHex = colorHex
        self.notes = notes
        self.createdAt = Date()
    }

    var dosesPerActiveDay: Int { doseTimes.count }
    var activeDayCount: Int { weekdays.isEmpty ? 7 : Set(weekdays).count }

    /// Average units consumed per calendar day across the week.
    var dailyConsumption: Double {
        Double(dosesPerActiveDay * activeDayCount) * unitsPerDose / 7.0
    }

    var daysOfSupply: Double {
        dailyConsumption > 0 ? quantityOnHand / dailyConsumption : .infinity
    }

    var sortedDoseTimes: [Int] { doseTimes.sorted() }

    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        guard isActive else { return false }
        if weekdays.isEmpty { return true }
        return weekdays.contains(calendar.component(.weekday, from: date))
    }
}

/// A record that a scheduled dose was taken or skipped.
@Model
final class DoseLog {
    var id: UUID = UUID()
    /// The scheduled date+time this log corresponds to.
    var scheduledAt: Date = Date()
    var status: String = "taken"   // "taken" / "skipped"
    var loggedAt: Date = Date()
    var medication: Medication?

    init(scheduledAt: Date, status: String, medication: Medication?) {
        self.id = UUID()
        self.scheduledAt = scheduledAt
        self.status = status
        self.loggedAt = Date()
        self.medication = medication
    }
}

/// A refill event that adds units to a medication's supply.
@Model
final class Refill {
    var id: UUID = UUID()
    var date: Date = Date()
    var quantity: Double = 0
    var pharmacy: String = ""
    var cost: Double = 0
    var medication: Medication?

    init(date: Date, quantity: Double, pharmacy: String = "", cost: Double = 0, medication: Medication?) {
        self.id = UUID()
        self.date = date
        self.quantity = max(0, quantity)
        self.pharmacy = pharmacy
        self.cost = cost
        self.medication = medication
    }
}
