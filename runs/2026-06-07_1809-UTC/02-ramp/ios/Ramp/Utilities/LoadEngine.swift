import Foundation
import SwiftUI

/// Pure training-load math. No SwiftData, no SwiftUI state — just inputs → outputs,
/// so it is trivially testable and never crashes on edge cases (zero FTP, no rides).
enum LoadEngine {

    // MARK: - Constants
    /// Time constant for Chronic Training Load (fitness), in days.
    static let ctlTimeConstant: Double = 42
    /// Time constant for Acute Training Load (fatigue), in days.
    static let atlTimeConstant: Double = 7

    // MARK: - TSS

    /// Intensity Factor from normalized power and FTP. Guards FTP = 0.
    static func intensityFactor(np: Int, ftp: Int) -> Double {
        guard ftp > 0 else { return 0 }
        return Double(np) / Double(ftp)
    }

    /// TSS from a power-based ride. Guards FTP = 0 and duration = 0.
    static func tssFromPower(np: Int, ftp: Int, durationMin: Int) -> Double {
        guard ftp > 0, durationMin > 0 else { return 0 }
        let ifv = intensityFactor(np: np, ftp: ftp)
        return (Double(durationMin) / 60.0) * ifv * ifv * 100.0
    }

    // MARK: - FTP lookup

    /// Watts of the latest FTPEntry with date ≤ the given date, else the fallback.
    static func ftp(on date: Date, entries: [FTPEntry], fallback: Int) -> Int {
        let candidates = entries
            .filter { $0.date <= date && $0.watts > 0 }
            .sorted { $0.date < $1.date }
        return candidates.last?.watts ?? max(0, fallback)
    }

    // MARK: - Performance Management Chart

    struct DayPoint: Identifiable {
        let id: Date
        let date: Date
        let ctl: Double
        let atl: Double
        let tsb: Double
        let tss: Double
        init(date: Date, ctl: Double, atl: Double, tsb: Double, tss: Double) {
            self.id = date
            self.date = date
            self.ctl = ctl
            self.atl = atl
            self.tsb = tsb
            self.tss = tss
        }
    }

    /// Daily TSS totals from the earliest ride (or today−90) through today, inclusive.
    /// Rest days contribute 0.
    static func dailyTSS(rides: [Ride], calendar: Calendar = .current, today: Date = Date()) -> [(date: Date, tss: Double)] {
        let endDay = calendar.startOfDay(for: today)
        let defaultStart = calendar.date(byAdding: .day, value: -90, to: endDay) ?? endDay
        let earliestRide = rides.map { calendar.startOfDay(for: $0.date) }.min()
        let startDay = min(earliestRide ?? defaultStart, defaultStart)

        // Bucket TSS by day.
        var buckets: [Date: Double] = [:]
        for ride in rides {
            let day = calendar.startOfDay(for: ride.date)
            buckets[day, default: 0] += ride.tss
        }

        var result: [(date: Date, tss: Double)] = []
        var cursor = startDay
        var guardCounter = 0
        while cursor <= endDay && guardCounter < 5000 {
            result.append((date: cursor, tss: buckets[cursor] ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            guardCounter += 1
        }
        return result
    }

    /// Full CTL/ATL/TSB series. Starts both EMAs at 0; TSB is yesterday's (CTL−ATL).
    static func series(rides: [Ride], calendar: Calendar = .current, today: Date = Date()) -> [DayPoint] {
        let daily = dailyTSS(rides: rides, calendar: calendar, today: today)
        guard !daily.isEmpty else { return [] }

        let ctlAlpha = 1 - exp(-1.0 / ctlTimeConstant)
        let atlAlpha = 1 - exp(-1.0 / atlTimeConstant)

        var points: [DayPoint] = []
        var prevCtl = 0.0
        var prevAtl = 0.0
        for day in daily {
            let tsb = prevCtl - prevAtl                       // yesterday's form
            let ctl = prevCtl + (day.tss - prevCtl) * ctlAlpha
            let atl = prevAtl + (day.tss - prevAtl) * atlAlpha
            points.append(DayPoint(date: day.date, ctl: ctl, atl: atl, tsb: tsb, tss: day.tss))
            prevCtl = ctl
            prevAtl = atl
        }
        return points
    }

    struct Snapshot {
        var fitness: Double = 0   // CTL
        var fatigue: Double = 0   // ATL
        var form: Double = 0      // TSB
        var rampRate: Double = 0  // CTL(today) − CTL(7 days ago)
        var hasData: Bool = false
    }

    /// Today's CTL/ATL/TSB plus the 7-day ramp rate.
    static func snapshot(rides: [Ride], calendar: Calendar = .current, today: Date = Date()) -> Snapshot {
        let pts = series(rides: rides, calendar: calendar, today: today)
        guard let last = pts.last else { return Snapshot() }
        var snap = Snapshot()
        snap.fitness = last.ctl
        snap.fatigue = last.atl
        snap.form = last.tsb
        snap.hasData = rides.contains { $0.tss > 0 }
        if pts.count > 7 {
            snap.rampRate = last.ctl - pts[pts.count - 8].ctl
        } else if let first = pts.first {
            snap.rampRate = last.ctl - first.ctl
        }
        return snap
    }

    // MARK: - Form status

    struct FormStatus {
        let label: String
        let color: Color
    }

    static func formStatus(tsb: Double) -> FormStatus {
        switch tsb {
        case let x where x > 25:
            return FormStatus(label: "Transition / very fresh", color: Brand.warn)
        case 5...25:
            return FormStatus(label: "Fresh", color: Brand.info)
        case (-10)..<5:
            return FormStatus(label: "Neutral / grey zone", color: Brand.text2)
        case (-30)..<(-10):
            return FormStatus(label: "Productive / training", color: Brand.live)
        default:
            return FormStatus(label: "High fatigue risk", color: Brand.danger)
        }
    }

    // MARK: - Power zones

    struct PowerZone: Identifiable {
        let id: Int            // 1...7
        let name: String
        let lowPct: Int        // inclusive lower %FTP bound
        let highPct: Int?      // inclusive upper %FTP bound; nil = open ended
        let lowWatts: Int
        let highWatts: Int?

        var number: Int { id }
        var pctLabel: String {
            if let high = highPct { return "\(lowPct)–\(high)%" }
            return ">\(lowPct - 1)%"
        }
        var wattLabel: String {
            if let high = highWatts { return "\(lowWatts)–\(high) W" }
            return "\(lowWatts)+ W"
        }
    }

    /// Coggan 7-zone model. Guards FTP = 0 by returning empty.
    static func powerZones(ftp: Int) -> [PowerZone] {
        guard ftp > 0 else { return [] }
        func w(_ pct: Int) -> Int { Int((Double(ftp) * Double(pct) / 100.0).rounded()) }
        return [
            PowerZone(id: 1, name: "Active Recovery", lowPct: 0,   highPct: 55,  lowWatts: 0,        highWatts: w(55)),
            PowerZone(id: 2, name: "Endurance",       lowPct: 56,  highPct: 75,  lowWatts: w(56),    highWatts: w(75)),
            PowerZone(id: 3, name: "Tempo",           lowPct: 76,  highPct: 90,  lowWatts: w(76),    highWatts: w(90)),
            PowerZone(id: 4, name: "Threshold",       lowPct: 91,  highPct: 105, lowWatts: w(91),    highWatts: w(105)),
            PowerZone(id: 5, name: "VO2 Max",         lowPct: 106, highPct: 120, lowWatts: w(106),   highWatts: w(120)),
            PowerZone(id: 6, name: "Anaerobic",       lowPct: 121, highPct: 150, lowWatts: w(121),   highWatts: w(150)),
            PowerZone(id: 7, name: "Neuromuscular",   lowPct: 151, highPct: nil, lowWatts: w(151),   highWatts: nil)
        ]
    }

    /// Power-to-weight. Guards weight = 0.
    static func wattsPerKg(ftp: Int, weightKg: Double) -> Double {
        guard weightKg > 0 else { return 0 }
        return Double(ftp) / weightKg
    }

    /// Which zone (1...7) a given normalized power falls in for a given FTP. 0 if undefined.
    static func zoneIndex(np: Int, ftp: Int) -> Int {
        guard ftp > 0, np > 0 else { return 0 }
        let pct = Double(np) / Double(ftp) * 100.0
        switch pct {
        case ..<55.5:  return 1
        case ..<75.5:  return 2
        case ..<90.5:  return 3
        case ..<105.5: return 4
        case ..<120.5: return 5
        case ..<150.5: return 6
        default:       return 7
        }
    }

    // MARK: - Weekly TSS

    struct WeekBucket: Identifiable {
        let id: Date          // start of ISO week
        let weekStart: Date
        let tss: Double
        let label: String
    }

    /// Sum of TSS per ISO week for the last `weeks` weeks (oldest → newest).
    static func weeklyTSS(rides: [Ride], weeks: Int = 12, calendar baseCal: Calendar = .current, today: Date = Date()) -> [WeekBucket] {
        var calendar = baseCal
        calendar.firstWeekday = 2 // Monday
        let thisWeekStart = startOfWeek(for: today, calendar: calendar)
        guard let earliest = calendar.date(byAdding: .day, value: -(weeks - 1) * 7, to: thisWeekStart) else { return [] }

        var buckets: [Date: Double] = [:]
        for ride in rides {
            let ws = startOfWeek(for: ride.date, calendar: calendar)
            if ws >= earliest {
                buckets[ws, default: 0] += ride.tss
            }
        }

        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.dateFormat = "d MMM"

        var result: [WeekBucket] = []
        var cursor = earliest
        var counter = 0
        while cursor <= thisWeekStart && counter < weeks + 2 {
            result.append(WeekBucket(id: cursor, weekStart: cursor, tss: buckets[cursor] ?? 0, label: fmt.string(from: cursor)))
            guard let next = calendar.date(byAdding: .day, value: 7, to: cursor) else { break }
            cursor = next
            counter += 1
        }
        return result
    }

    static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? calendar.startOfDay(for: date)
    }

    // MARK: - Time in zone

    struct ZoneTime: Identifiable {
        let id: Int           // zone number 1...7
        let zone: Int
        let name: String
        let minutes: Int
        let color: Color
    }

    static let zoneNames = ["", "Z1 Recovery", "Z2 Endurance", "Z3 Tempo", "Z4 Threshold", "Z5 VO2", "Z6 Anaerobic", "Z7 Neuro"]

    static func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Brand.text3
        case 2: return Brand.info
        case 3: return Brand.live
        case 4: return Brand.magic
        case 5: return Brand.warn
        case 6: return Brand.danger
        case 7: return Brand.danger
        default: return Brand.text2
        }
    }

    /// Minutes spent in each zone, classifying every power ride's NP. Manual rides ignored.
    static func timeInZone(rides: [Ride]) -> [ZoneTime] {
        var minutes = Array(repeating: 0, count: 8) // index 1...7
        for ride in rides where ride.entry == .power {
            let z = zoneIndex(np: ride.normalizedPower, ftp: ride.ftpAtTime)
            guard z >= 1 && z <= 7 else { continue }
            minutes[z] += max(0, ride.durationMin)
        }
        return (1...7).map { z in
            ZoneTime(id: z, zone: z, name: zoneNames[z], minutes: minutes[z], color: zoneColor(z))
        }
    }
}
