import Foundation

/// Pure fuel-economy and maintenance logic. Distances in km, volume in liters.
enum GarageEngine {

    // MARK: - Fuel economy (partial-fill aware)

    /// One measured fuel interval between two full tanks.
    struct EconomyPoint: Identifiable {
        let id = UUID()
        let date: Date
        let km: Double          // distance covered in the interval
        let liters: Double      // fuel used in the interval (incl. partials)
        var l100: Double { km > 0 ? liters / (km / 100) : 0 }
    }

    /// Compute economy intervals. The fuel burned between two full tanks is the
    /// sum of all fills *after* the first full tank up to and including the next
    /// full tank; distance is the odometer delta between the two full tanks.
    static func economyPoints(_ entries: [FuelEntry]) -> [EconomyPoint] {
        let sorted = entries.sorted { $0.odometerKm < $1.odometerKm }
        var points: [EconomyPoint] = []
        var lastFullIndex: Int? = nil
        var litersSinceFull = 0.0

        for (i, e) in sorted.enumerated() {
            if let lf = lastFullIndex {
                litersSinceFull += e.liters
                if e.isFullTank {
                    let km = e.odometerKm - sorted[lf].odometerKm
                    if km > 0 {
                        points.append(EconomyPoint(date: e.date, km: km, liters: litersSinceFull))
                    }
                    lastFullIndex = i
                    litersSinceFull = 0
                }
            } else if e.isFullTank {
                lastFullIndex = i
                litersSinceFull = 0
            }
        }
        return points
    }

    struct FuelSummary {
        let averageL100: Double
        let bestL100: Double
        let totalLiters: Double
        let totalCost: Double
        let fillCount: Int
        let totalDistanceKm: Double
    }

    static func fuelSummary(_ entries: [FuelEntry]) -> FuelSummary {
        let points = economyPoints(entries)
        let totalKm = points.reduce(0) { $0 + $1.km }
        let totalLitersInIntervals = points.reduce(0) { $0 + $1.liters }
        let avg = totalKm > 0 ? totalLitersInIntervals / (totalKm / 100) : 0
        let best = points.map(\.l100).filter { $0 > 0 }.min() ?? 0
        return FuelSummary(averageL100: avg,
                           bestL100: best,
                           totalLiters: entries.reduce(0) { $0 + $1.liters },
                           totalCost: entries.reduce(0) { $0 + $1.totalCost },
                           fillCount: entries.count,
                           totalDistanceKm: totalKm)
    }

    // MARK: - Reminder status

    enum ReminderState {
        case overdue, dueSoon, ok
    }

    struct ReminderStatus {
        let state: ReminderState
        let kmRemaining: Double?    // nil if no distance trigger
        let daysRemaining: Int?     // nil if no date trigger
        let detail: String
    }

    static func status(for reminder: ServiceReminder,
                       currentOdometerKm: Double,
                       now: Date = .now,
                       calendar: Calendar = .current,
                       soonKm: Double = 500,
                       soonDays: Int = 14) -> ReminderStatus {
        var kmRemaining: Double? = nil
        var daysRemaining: Int? = nil
        var states: [ReminderState] = []

        if reminder.dueOdometerKm > 0 {
            let rem = reminder.dueOdometerKm - currentOdometerKm
            kmRemaining = rem
            states.append(rem <= 0 ? .overdue : (rem <= soonKm ? .dueSoon : .ok))
        }
        if let due = reminder.dueDate {
            let days = calendar.dateComponents([.day],
                                               from: calendar.startOfDay(for: now),
                                               to: calendar.startOfDay(for: due)).day ?? 0
            daysRemaining = days
            states.append(days < 0 ? .overdue : (days <= soonDays ? .dueSoon : .ok))
        }

        let worst: ReminderState = states.contains(.overdue) ? .overdue
            : (states.contains(.dueSoon) ? .dueSoon : .ok)

        var bits: [String] = []
        if let km = kmRemaining {
            bits.append(km <= 0 ? "\(Int(-km)) km over" : "in \(Int(km)) km")
        }
        if let d = daysRemaining {
            bits.append(d < 0 ? "\(-d) days late" : "in \(d) days")
        }
        let detail = bits.isEmpty ? "No trigger set" : bits.joined(separator: " · ")
        return ReminderStatus(state: worst, kmRemaining: kmRemaining,
                              daysRemaining: daysRemaining, detail: detail)
    }

    /// Advance a repeating reminder past its current due point.
    static func roll(_ reminder: ServiceReminder,
                     currentOdometerKm: Double,
                     now: Date = .now,
                     calendar: Calendar = .current) {
        if reminder.repeatEveryKm > 0 {
            reminder.dueOdometerKm = max(currentOdometerKm, reminder.dueOdometerKm) + reminder.repeatEveryKm
        }
        if reminder.repeatEveryMonths > 0 {
            let base = max(reminder.dueDate ?? now, now)
            reminder.dueDate = calendar.date(byAdding: .month, value: reminder.repeatEveryMonths, to: base)
        }
        if reminder.repeatEveryKm == 0 && reminder.repeatEveryMonths == 0 {
            reminder.isActive = false
        }
    }

    // MARK: - Spend

    static func totalSpend(_ vehicle: Vehicle) -> Double {
        vehicle.fuelEntries.reduce(0) { $0 + $1.totalCost }
            + vehicle.services.reduce(0) { $0 + $1.cost }
    }

    static func spendThisMonth(_ vehicle: Vehicle, now: Date = .now, calendar: Calendar = .current) -> Double {
        let comps = calendar.dateComponents([.year, .month], from: now)
        func sameMonth(_ d: Date) -> Bool {
            let c = calendar.dateComponents([.year, .month], from: d)
            return c.year == comps.year && c.month == comps.month
        }
        return vehicle.fuelEntries.filter { sameMonth($0.date) }.reduce(0) { $0 + $1.totalCost }
            + vehicle.services.filter { sameMonth($0.date) }.reduce(0) { $0 + $1.cost }
    }

    struct MonthSpend: Identifiable {
        let id = UUID()
        let month: Date
        let fuel: Double
        let service: Double
        var total: Double { fuel + service }
    }

    static func monthlySpend(_ vehicle: Vehicle, months: Int = 6,
                             now: Date = .now, calendar: Calendar = .current) -> [MonthSpend] {
        let startOfThis = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0..<months).reversed().compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: startOfThis) else { return nil }
            let next = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            func inMonth(_ d: Date) -> Bool { d >= monthStart && d < next }
            let fuel = vehicle.fuelEntries.filter { inMonth($0.date) }.reduce(0) { $0 + $1.totalCost }
            let service = vehicle.services.filter { inMonth($0.date) }.reduce(0) { $0 + $1.cost }
            return MonthSpend(month: monthStart, fuel: fuel, service: service)
        }
    }
}
