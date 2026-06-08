import Foundation

enum CareStatus {
    case overdue(days: Int)
    case dueToday
    case dueSoon(days: Int)
    case ok(days: Int)

    var isUrgent: Bool {
        switch self {
        case .overdue: return true
        case .dueToday: return true
        default: return false
        }
    }

    var sortPriority: Int {
        switch self {
        case .overdue(let d): return -(d + 1000)
        case .dueToday:       return 0
        case .dueSoon(let d): return d
        case .ok(let d):      return d + 100
        }
    }
}

struct CareTask: Identifiable {
    let id: UUID
    let plant: Plant
    let type: CareType
    let due: Date
    let status: CareStatus
}

enum CareEngine {

    // MARK: - Seasonal multiplier

    /// Returns an adjusted interval (clamped to >=1) based on current month.
    /// Summer (Jun–Aug): 20% shorter. Winter (Dec–Feb): 30% longer.
    static func seasonalMultiplier(for date: Date) -> Double {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 6, 7, 8:    return 0.80
        case 12, 1, 2:   return 1.30
        default:          return 1.00
        }
    }

    static func adjustedWateringInterval(_ plant: Plant, seasonalAdjust: Bool, now: Date) -> Int {
        guard plant.wateringIntervalDays > 0 else { return 1 }
        if seasonalAdjust {
            let raw = Double(plant.wateringIntervalDays) * seasonalMultiplier(for: now)
            return max(1, Int(raw.rounded()))
        }
        return plant.wateringIntervalDays
    }

    // MARK: - Due dates

    static func nextWaterDue(plant: Plant, seasonalAdjust: Bool, now: Date) -> Date? {
        let base = plant.lastWatered ?? plant.acquired
        let interval = adjustedWateringInterval(plant, seasonalAdjust: seasonalAdjust, now: now)
        return Calendar.current.date(byAdding: .day, value: interval, to: base)
    }

    static func nextFertilizeDue(plant: Plant, now: Date) -> Date? {
        guard plant.fertilizeIntervalDays > 0 else { return nil }
        let month = Calendar.current.component(.month, from: now)
        // Skip fertilizing in winter months
        if month == 12 || month == 1 || month == 2 { return nil }
        let base = plant.lastFertilized ?? plant.acquired
        return Calendar.current.date(byAdding: .day, value: plant.fertilizeIntervalDays, to: base)
    }

    // MARK: - Status

    static func daysUntil(_ date: Date, now: Date) -> Int {
        let cal = Calendar.current
        let fromDay = cal.startOfDay(for: now)
        let toDay = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
    }

    static func status(plant: Plant, seasonalAdjust: Bool, now: Date) -> CareStatus {
        let waterDue = nextWaterDue(plant: plant, seasonalAdjust: seasonalAdjust, now: now)
        let fertilizeDue = nextFertilizeDue(plant: plant, now: now)

        var soonestDays: Int = Int.max
        if let w = waterDue {
            let d = daysUntil(w, now: now)
            if d < soonestDays { soonestDays = d }
        }
        if let f = fertilizeDue {
            let d = daysUntil(f, now: now)
            if d < soonestDays { soonestDays = d }
        }
        if soonestDays == Int.max { return .ok(days: 999) }
        return statusFrom(days: soonestDays)
    }

    static func statusFrom(days: Int) -> CareStatus {
        if days < 0  { return .overdue(days: -days) }
        if days == 0 { return .dueToday }
        if days <= 2 { return .dueSoon(days: days) }
        return .ok(days: days)
    }

    // MARK: - Today's Tasks

    static func todaysTasks(plants: [Plant], seasonalAdjust: Bool, now: Date) -> [CareTask] {
        var tasks: [CareTask] = []

        for plant in plants where !plant.archived {
            if let due = nextWaterDue(plant: plant, seasonalAdjust: seasonalAdjust, now: now) {
                let days = daysUntil(due, now: now)
                if days <= 3 {
                    let st = statusFrom(days: days)
                    tasks.append(CareTask(id: UUID(), plant: plant, type: .water, due: due, status: st))
                }
            }
            if let due = nextFertilizeDue(plant: plant, now: now) {
                let days = daysUntil(due, now: now)
                if days <= 3 {
                    let st = statusFrom(days: days)
                    tasks.append(CareTask(id: UUID(), plant: plant, type: .fertilize, due: due, status: st))
                }
            }
        }

        return tasks.sorted { $0.status.sortPriority < $1.status.sortPriority }
    }
}
