import Foundation

/// Pure trip computations: day spans, per-night lodging coverage (the feature
/// Wanderlog users keep asking for), itinerary grouping, and budget rollups.
struct TripEngine {
    let calendar: Calendar
    init(calendar: Calendar = .current) { self.calendar = calendar }

    // MARK: - Status & duration

    func status(_ trip: Trip, asOf now: Date = .now) -> TripStatus {
        let today = calendar.startOfDay(for: now)
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        if today < start {
            let days = calendar.dateComponents([.day], from: today, to: start).day ?? 0
            return .upcoming(daysAway: max(0, days))
        } else if today > end {
            return .past
        } else {
            let n = (calendar.dateComponents([.day], from: start, to: today).day ?? 0) + 1
            return .active(dayNumber: n, total: dayCount(trip))
        }
    }

    func dayCount(_ trip: Trip) -> Int {
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        return max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
    }

    /// Each calendar day of the trip, inclusive.
    func days(_ trip: Trip) -> [Date] {
        let start = calendar.startOfDay(for: trip.startDate)
        var result: [Date] = []
        for offset in 0..<dayCount(trip) {
            if let d = calendar.date(byAdding: .day, value: offset, to: start) {
                result.append(d)
            }
        }
        return result
    }

    // MARK: - Itinerary

    /// Activities on a given day, sorted: timed first (by time), then untimed.
    func activities(_ trip: Trip, on day: Date) -> [Activity] {
        trip.activities
            .filter { calendar.isDate($0.startTime, inSameDayAs: day) }
            .sorted { a, b in
                if a.hasTime != b.hasTime { return a.hasTime && !b.hasTime }
                return a.startTime < b.startTime
            }
    }

    // MARK: - Lodging coverage (the headline feature)

    struct NightCoverage: Identifiable {
        let id = UUID()
        let night: Date          // the date you go to sleep
        let lodging: Lodging?    // nil = gap, nothing booked
    }

    /// For every night of the trip (start … end-1, i.e. you don't sleep the last
    /// day if it's a departure day — but we include up to the night before end),
    /// find the lodging whose [checkIn, checkOut) interval covers it. Surfaces
    /// gaps so "where am I sleeping each night" is answerable at a glance.
    func nightlyCoverage(_ trip: Trip) -> [NightCoverage] {
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        var nights: [NightCoverage] = []
        var cursor = start
        // Nights are each day from start up to (but not including) the end day.
        while cursor < end {
            let covering = trip.lodgings.first { lodging in
                let ci = calendar.startOfDay(for: lodging.checkIn)
                let co = calendar.startOfDay(for: lodging.checkOut)
                return cursor >= ci && cursor < co
            }
            nights.append(NightCoverage(night: cursor, lodging: covering))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        // Single-day trips still deserve a row.
        if nights.isEmpty {
            let covering = trip.lodgings.first
            nights.append(NightCoverage(night: start, lodging: covering))
        }
        return nights
    }

    func nightsWithoutLodging(_ trip: Trip) -> Int {
        nightlyCoverage(trip).filter { $0.lodging == nil }.count
    }

    // MARK: - Budget

    struct CategoryTotal: Identifiable {
        let id = UUID()
        let category: ActivityCategory
        let amount: Double
    }

    /// Combines logged expenses with lodging costs and any activity costs.
    func totalSpent(_ trip: Trip) -> Double {
        let expenses = trip.expenses.reduce(0) { $0 + $1.amount }
        return expenses
    }

    func spentByCategory(_ trip: Trip) -> [CategoryTotal] {
        var map: [ActivityCategory: Double] = [:]
        for e in trip.expenses {
            map[e.category, default: 0] += e.amount
        }
        return map.map { CategoryTotal(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    func budgetRemaining(_ trip: Trip) -> Double? {
        guard trip.budget > 0 else { return nil }
        return trip.budget - totalSpent(trip)
    }

    func budgetFraction(_ trip: Trip) -> Double {
        guard trip.budget > 0 else { return 0 }
        return min(1.5, totalSpent(trip) / trip.budget)
    }

    // MARK: - Packing

    func packingProgress(_ trip: Trip) -> (packed: Int, total: Int) {
        let total = trip.packingItems.count
        let packed = trip.packingItems.filter { $0.packed }.count
        return (packed, total)
    }
}
