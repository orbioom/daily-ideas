import Foundation

/// One slice of the energy-by-category breakdown.
struct CategoryEnergy: Identifiable, Hashable {
    let category: LoadCategory
    let dailyWh: Double
    var id: String { category.rawValue }
}

/// Inverter sizing verdict for the AC loads on a system.
enum InverterStatus: Equatable {
    case none          // no inverter configured
    case ok            // inverter present and large enough
    case over          // peak AC demand exceeds the inverter rating
    case noACLoads     // inverter present but nothing draws AC

    var label: String {
        switch self {
        case .none:      return "No inverter"
        case .ok:        return "Within rating"
        case .over:      return "Over rating"
        case .noACLoads: return "Idle"
        }
    }
}

/// The complete computed picture for a system. All divisions inside are guarded;
/// "indefinite" autonomy is represented by `Double.infinity`, which the UI handles.
struct PowerResult {
    var systemDailyWh: Double = 0
    var dailyAh: Double = 0

    var usableWh: Double = 0
    var usableAh: Double = 0
    var usableDoD: Double = 0

    /// Days the bank lasts with no solar input. `.infinity` when there is no load.
    var daysAutonomyNoSolar: Double = 0

    var solarHarvestWh: Double = 0
    /// Solar reaching the battery (after charge efficiency) minus daily consumption.
    var netDailyWh: Double = 0

    /// Hours of full sun to refill the usable bank. `.infinity` when there is no solar.
    var rechargeHoursFromEmpty: Double = 0

    /// Effective autonomy accounting for solar. `.infinity` when net is non-negative.
    var effectiveAutonomyDays: Double = 0
    var isSelfSustaining: Bool = false

    var peakACWatts: Double = 0
    var inverterStatus: InverterStatus = .none
    var inverterHeadroomFraction: Double = 0   // 0...1, peakAC / inverterWatts

    var categoryBreakdown: [CategoryEnergy] = []

    /// Fraction of the day's consumption covered by solar (0...1+, clamped for meters).
    var solarCoverageFraction: Double = 0
}

/// Pure functions that turn a `PowerSystem` (or raw inputs) into a `PowerResult`.
/// No SwiftUI, no SwiftData mutation — safe to call from anywhere, easy to reason about.
enum PowerEngine {

    // MARK: - Full system evaluation

    static func evaluate(_ system: PowerSystem) -> PowerResult {
        evaluate(
            loads: system.loads,
            batteryCapacityAh: system.batteryCapacityAh,
            systemVoltage: system.systemVoltage,
            usableDoD: system.usableDoD,
            solarWatts: system.solarWatts,
            peakSunHours: system.peakSunHours,
            solarEfficiency: system.solarEfficiency,
            chargeEfficiency: system.chargeEfficiency,
            inverterWatts: system.inverterWatts
        )
    }

    static func evaluate(
        loads: [Load],
        batteryCapacityAh: Double,
        systemVoltage: Int,
        usableDoD: Double,
        solarWatts: Double,
        peakSunHours: Double,
        solarEfficiency: Double,
        chargeEfficiency: Double,
        inverterWatts: Double
    ) -> PowerResult {
        var r = PowerResult()
        let voltage = Double(systemVoltage)

        // Consumption
        r.systemDailyWh = loads.reduce(0) { $0 + $1.dailyWh }
        r.dailyAh = systemVoltage > 0 ? r.systemDailyWh / voltage : 0

        // Storage
        r.usableDoD = usableDoD
        r.usableWh = batteryCapacityAh * voltage * usableDoD
        r.usableAh = batteryCapacityAh * usableDoD

        // Autonomy without solar
        r.daysAutonomyNoSolar = r.systemDailyWh > 0 ? r.usableWh / r.systemDailyWh : .infinity

        // Solar harvest and net balance
        r.solarHarvestWh = solarWatts * peakSunHours * solarEfficiency
        let solarToBattery = r.solarHarvestWh * chargeEfficiency
        r.netDailyWh = solarToBattery - r.systemDailyWh
        r.solarCoverageFraction = r.systemDailyWh > 0 ? solarToBattery / r.systemDailyWh : (solarToBattery > 0 ? 1 : 0)

        // Recharge time
        let chargePower = solarWatts * solarEfficiency
        r.rechargeHoursFromEmpty = chargePower > 0 ? r.usableWh / chargePower : .infinity

        // Effective autonomy with solar
        if r.netDailyWh >= 0 {
            r.effectiveAutonomyDays = .infinity
            r.isSelfSustaining = true
        } else {
            let deficit = abs(r.netDailyWh)
            r.effectiveAutonomyDays = deficit > 0 ? r.usableWh / deficit : .infinity
            r.isSelfSustaining = false
        }

        // Inverter check
        r.peakACWatts = loads.filter { $0.isAC }
            .reduce(0) { $0 + $1.watts * Double(max($1.quantity, 0)) }
        if inverterWatts <= 0 {
            r.inverterStatus = .none
            r.inverterHeadroomFraction = 0
        } else if r.peakACWatts <= 0 {
            r.inverterStatus = .noACLoads
            r.inverterHeadroomFraction = 0
        } else {
            r.inverterHeadroomFraction = min(1, r.peakACWatts / inverterWatts)
            r.inverterStatus = r.peakACWatts <= inverterWatts ? .ok : .over
        }

        // Category breakdown
        r.categoryBreakdown = breakdown(for: loads)

        return r
    }

    // MARK: - Breakdown

    static func breakdown(for loads: [Load]) -> [CategoryEnergy] {
        var totals: [LoadCategory: Double] = [:]
        for load in loads {
            totals[load.category, default: 0] += load.dailyWh
        }
        return totals
            .filter { $0.value > 0 }
            .map { CategoryEnergy(category: $0.key, dailyWh: $0.value) }
            .sorted { $0.dailyWh > $1.dailyWh }
    }

    // MARK: - Sizing recommendations

    /// Battery amp-hours needed to cover `days` of consumption at the given DoD.
    static func recommendedBatteryAh(
        dailyWh: Double,
        days: Double,
        systemVoltage: Int,
        usableDoD: Double
    ) -> Double {
        let denom = Double(systemVoltage) * usableDoD
        guard denom > 0, days > 0 else { return 0 }
        return dailyWh * days / denom
    }

    /// Solar watts needed for daily harvest to break even with consumption.
    static func recommendedSolarW(
        dailyWh: Double,
        peakSunHours: Double,
        solarEfficiency: Double,
        chargeEfficiency: Double
    ) -> Double {
        let denom = peakSunHours * solarEfficiency * chargeEfficiency
        guard denom > 0 else { return 0 }
        return dailyWh / denom
    }
}
