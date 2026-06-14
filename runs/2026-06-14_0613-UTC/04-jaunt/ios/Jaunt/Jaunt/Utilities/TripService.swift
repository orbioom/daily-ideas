import Foundation
import SwiftData

/// Mutation helpers that keep a Trip's TripDays consistent with its date range,
/// plus first-launch seeding and a reset action. Kept free of SwiftUI so it can
/// be reasoned about purely.
enum TripService {

    // MARK: Day synchronisation

    /// Ensure a trip has exactly one TripDay per calendar day in its (inclusive)
    /// range. Existing days that still fall inside the range are preserved
    /// (keeping their items and titles); out-of-range days are removed; missing
    /// days are inserted. DST-safe via calendar-day comparison.
    static func syncDays(for trip: Trip, context: ModelContext) {
        let cal = ItineraryEngine.calendar
        let wanted = ItineraryEngine.dayDates(from: trip.startDate, to: trip.endDate, calendar: cal)
        let wantedSet = Set(wanted.map { cal.startOfDay(for: $0) })

        // Remove days no longer in range.
        for day in trip.days {
            let key = cal.startOfDay(for: day.date)
            if !wantedSet.contains(key) {
                context.delete(day)
            }
        }

        // Index surviving days by their start-of-day.
        var existing: [Date: TripDay] = [:]
        for day in trip.days {
            let key = cal.startOfDay(for: day.date)
            if wantedSet.contains(key) {
                existing[key] = day
            }
        }

        // Insert any missing days.
        for date in wanted {
            let key = cal.startOfDay(for: date)
            if existing[key] == nil {
                let newDay = TripDay(date: key)
                context.insert(newDay)
                // Set the to-one side; SwiftData maintains trip.days inversely.
                newDay.trip = trip
            }
        }
    }

    /// Days sorted chronologically.
    static func orderedDays(_ trip: Trip) -> [TripDay] {
        trip.days.sorted { $0.date < $1.date }
    }

    // MARK: Itinerary export (Pro)

    /// Build a clean text representation of the whole trip for sharing/copy.
    static func itineraryText(for trip: Trip, use24h: Bool, currencySymbol: String) -> String {
        var lines: [String] = []
        lines.append(trip.name)
        if !trip.destination.isEmpty { lines.append(trip.destination) }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        lines.append("\(df.string(from: trip.startDate)) – \(df.string(from: trip.endDate))")
        lines.append("")

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEEE, MMM d"
        for (idx, day) in orderedDays(trip).enumerated() {
            var header = "Day \(idx + 1) · \(dayFmt.string(from: day.date))"
            if !day.title.isEmpty { header += " — \(day.title)" }
            lines.append(header)
            let items = ItineraryEngine.sortedItems(day.items)
            if items.isEmpty {
                lines.append("  (no plans)")
            } else {
                for item in items {
                    let time = item.isTimed
                        ? ItineraryEngine.timeLabel(minutes: item.startTimeMinutes, use24h: use24h)
                        : "Anytime"
                    var line = "  • \(time)  \(item.title)"
                    if item.cost > 0 {
                        line += "  (\(BudgetEngine.currencyString(item.cost, symbol: currencySymbol)))"
                    }
                    lines.append(line)
                    if !item.address.isEmpty { lines.append("      \(item.address)") }
                }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Reset

    /// Delete all trips (cascades to days/items/packing/expenses) and clear seed flag.
    static func resetAll(trips: [Trip], context: ModelContext) {
        for trip in trips { context.delete(trip) }
        UserDefaults.standard.set(false, forKey: "didSeed")
    }
}
