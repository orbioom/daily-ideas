import Foundation

struct ChargingStats {
    let totalKWh: Double
    let totalCost: Double
    let sessionCount: Int
    let avgCostPerKWh: Double
    let avgKWhPerSession: Double
    let avgDurationMinutes: Double
    let co2SavedKg: Double
    let gasEquivSaved: Double

    static let empty = ChargingStats(
        totalKWh: 0, totalCost: 0, sessionCount: 0,
        avgCostPerKWh: 0, avgKWhPerSession: 0, avgDurationMinutes: 0,
        co2SavedKg: 0, gasEquivSaved: 0
    )
}

struct MonthlyBucket: Identifiable {
    let id: String
    let month: Date
    let kwhAdded: Double
    let cost: Double
    let sessions: Int
}

enum ChargingEngine {
    static func stats(from sessions: [ChargingSession]) -> ChargingStats {
        guard !sessions.isEmpty else { return .empty }
        let totalKWh = sessions.reduce(0) { $0 + $1.kwhAdded }
        let totalCost = sessions.reduce(0) { $0 + $1.cost }
        let avgCPK = totalKWh > 0 ? totalCost / totalKWh : 0
        let avgKWh = Double(sessions.count) > 0 ? totalKWh / Double(sessions.count) : 0
        let avgDur = sessions.reduce(0.0) { $0 + $1.durationMinutes } / Double(sessions.count)
        // CO2 savings: avg US grid ~0.38 kg CO2/kWh vs gas ~2.31 kg CO2/L (8.7 kg/gal)
        let co2Saved = totalKWh * (0.85 - 0.38)
        // Gas equivalent: EV ~3.5 miles/kWh vs 25 MPG ICE → gas saved in gallons
        let gasEquiv = totalKWh * 3.5 / 25.0
        return ChargingStats(
            totalKWh: totalKWh,
            totalCost: totalCost,
            sessionCount: sessions.count,
            avgCostPerKWh: avgCPK,
            avgKWhPerSession: avgKWh,
            avgDurationMinutes: avgDur,
            co2SavedKg: co2Saved,
            gasEquivSaved: gasEquiv
        )
    }

    static func monthlyBuckets(from sessions: [ChargingSession], months: Int = 6) -> [MonthlyBucket] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyBucket] = []
        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: calendar.startOfMonth(now)) else { continue }
            guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let bucket = sessions.filter { $0.date >= monthStart && $0.date < monthEnd }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            result.append(MonthlyBucket(
                id: formatter.string(from: monthStart),
                month: monthStart,
                kwhAdded: bucket.reduce(0) { $0 + $1.kwhAdded },
                cost: bucket.reduce(0) { $0 + $1.cost },
                sessions: bucket.count
            ))
        }
        return result
    }

    static func chargerBreakdown(from sessions: [ChargingSession]) -> [(ChargerType, Int)] {
        let grouped = Dictionary(grouping: sessions, by: { $0.chargerType })
        return ChargerType.allCases.compactMap { type in
            let count = grouped[type]?.count ?? 0
            return count > 0 ? (type, count) : nil
        }.sorted { $0.1 > $1.1 }
    }
}

private extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
