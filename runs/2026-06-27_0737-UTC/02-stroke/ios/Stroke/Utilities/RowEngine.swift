import Foundation

struct WeeklyBucket: Identifiable {
    let id: String
    let weekStart: Date
    let distanceM: Int
    let sessions: Int
}

struct MonthlyBucketRow: Identifiable {
    let id: String
    let month: Date
    let distanceM: Int
    let sessions: Int
}

enum RowEngine {
    // 500m split in seconds → watts: P = 2.80 / (split/500)^3
    static func splitToWatts(_ splitSec: Int) -> Double {
        guard splitSec > 0 else { return 0 }
        let ratio = Double(splitSec) / 500.0
        return 2.80 / (ratio * ratio * ratio)
    }

    // Watts → split seconds
    static func wattsToSplit(_ watts: Double) -> Int {
        guard watts > 0 else { return 0 }
        let ratio = pow(2.80 / watts, 1.0 / 3.0)
        return Int(ratio * 500)
    }

    static func formatSplit(_ seconds: Int) -> String {
        guard seconds > 0 else { return "--:--" }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    static func formatDuration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "0:00" }
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    // Training zone from avg watts (rough classification)
    static func zone(watts: Double) -> (name: String, color: String) {
        switch watts {
        case ..<100: return ("UT2", "blue")
        case 100..<130: return ("UT1", "cyan")
        case 130..<160: return ("AT", "green")
        case 160..<200: return ("TR", "yellow")
        default: return ("AN", "red")
        }
    }

    static func weeklyBuckets(from workouts: [RowWorkout], count: Int = 8) -> [WeeklyBucket] {
        let cal = Calendar.current
        let now = Date()
        return (0..<count).reversed().map { offset -> WeeklyBucket in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfWeek(now)) ?? now
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) ?? now
            let bucket = workouts.filter { $0.date >= weekStart && $0.date < weekEnd }
            let fmt = DateFormatter()
            fmt.dateFormat = "MM/dd"
            return WeeklyBucket(
                id: fmt.string(from: weekStart),
                weekStart: weekStart,
                distanceM: bucket.reduce(0) { $0 + $1.distanceM },
                sessions: bucket.count
            )
        }
    }

    static func checkPR(workout: RowWorkout, existing: [RowPR]) -> [PRCategory] {
        var newPRs: [PRCategory] = []
        for cat in PRCategory.allCases {
            if cat.isDistance, let target = cat.targetMeters {
                guard workout.distanceM >= target else { continue }
                let time = workout.timeSeconds
                let existing = existing.first { $0.category == cat }
                if existing == nil || time < existing!.value {
                    newPRs.append(cat)
                }
            } else if !cat.isDistance, let target = cat.targetSeconds {
                guard workout.timeSeconds >= target else { continue }
                let dist = workout.distanceM
                let existing = existing.first { $0.category == cat }
                if existing == nil || dist > existing!.value {
                    newPRs.append(cat)
                }
            }
        }
        return newPRs
    }
}

private extension Calendar {
    func startOfWeek(_ date: Date) -> Date {
        var comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2  // Monday
        return self.date(from: comps) ?? date
    }
}
