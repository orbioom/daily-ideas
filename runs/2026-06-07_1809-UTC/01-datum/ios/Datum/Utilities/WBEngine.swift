import Foundation
import CoreGraphics

/// Pure weight & balance math. No SwiftData, no SwiftUI — just inputs to results
/// so it is trivially testable and reusable across screens.
///
/// Conventions: weight in pounds (lb), arm in inches (in) aft of datum, moment in
/// inch-pounds (in-lb). The CG envelope is treated as a polygon with x = CG arm
/// and y = weight.
enum WBEngine {

    // MARK: - Core primitives

    /// Moment = weight × arm.
    static func moment(weight: Double, arm: Double) -> Double {
        weight * arm
    }

    /// One weighted item in a loadout (empty aircraft, a station load, fuel…).
    struct LoadItem: Identifiable, Hashable {
        var id = UUID()
        var label: String
        var weight: Double
        var arm: Double
        var moment: Double { weight * arm }
    }

    /// A computed weight/CG state for one scenario.
    struct Point: Hashable {
        var weight: Double
        var cg: Double
    }

    /// Which scenario a point represents, in flight order.
    enum Scenario: String, CaseIterable, Identifiable {
        case ramp = "Ramp"
        case takeoff = "Takeoff"
        case landing = "Landing"
        case zeroFuel = "Zero fuel"
        var id: String { rawValue }
    }

    /// The status of a single scenario after limit + envelope checks.
    struct ScenarioResult: Identifiable {
        var id: String { scenario.rawValue }
        var scenario: Scenario
        var point: Point
        var fuelGal: Double
        var withinEnvelope: Bool
        var withinWeightLimit: Bool
        var weightLimit: Double      // the limit that applied (0 = N/A)
        /// Overall pass requires both envelope and weight checks.
        var isOK: Bool { withinEnvelope && withinWeightLimit }
    }

    /// The full result for a flight: every scenario plus a roll-up.
    struct FlightResult {
        var items: [LoadItem]           // ramp loadout breakdown (full fuel)
        var scenarios: [ScenarioResult]
        var allowableCGRange: ClosedRange<Double>?  // at takeoff weight
        var allOK: Bool { scenarios.allSatisfy { $0.isOK } }
        /// The single worst scenario to surface (first failing, else ramp).
        var worst: ScenarioResult? {
            scenarios.first(where: { !$0.isOK }) ?? scenarios.first
        }
    }

    /// Parameters needed to compute a flight, decoupled from the data layer.
    struct FlightInputs {
        var emptyWeight: Double
        var emptyArm: Double
        var fuelGal: Double
        var plannedBurnGal: Double
        var taxiBurnGal: Double
        var fuelArm: Double
        var fuelWeightPerGal: Double
        /// Station loads as (label, weight, arm).
        var loads: [(label: String, weight: Double, arm: Double)]
        /// CG envelope polygon vertices (x = cg, y = weight), in perimeter order.
        var envelope: [EnvelopeVertex]
        var maxRampWeight: Double
        var maxTakeoffWeight: Double
        var maxLandingWeight: Double
        var maxZeroFuelWeight: Double
    }

    // MARK: - Loadout summation

    /// Sums a loadout for a given fuel quantity, returning the resulting weight
    /// and CG. Guards against a zero total weight (returns cg 0).
    static func summarize(
        emptyWeight: Double, emptyArm: Double,
        loads: [(label: String, weight: Double, arm: Double)],
        fuelGal: Double, fuelArm: Double, fuelWeightPerGal: Double
    ) -> Point {
        var totalWeight = emptyWeight
        var totalMoment = moment(weight: emptyWeight, arm: emptyArm)

        for load in loads {
            totalWeight += load.weight
            totalMoment += moment(weight: load.weight, arm: load.arm)
        }

        let fuelWeight = fuelGal * fuelWeightPerGal
        totalWeight += fuelWeight
        totalMoment += moment(weight: fuelWeight, arm: fuelArm)

        let cg = totalWeight > 0 ? totalMoment / totalWeight : 0
        return Point(weight: totalWeight, cg: cg)
    }

    /// Builds the itemized breakdown for the ramp (full requested) fuel state.
    static func breakdown(_ inputs: FlightInputs) -> [LoadItem] {
        var items: [LoadItem] = [
            LoadItem(label: "Empty aircraft", weight: inputs.emptyWeight, arm: inputs.emptyArm)
        ]
        for load in inputs.loads where load.weight != 0 {
            items.append(LoadItem(label: load.label, weight: load.weight, arm: load.arm))
        }
        let fuelWeight = inputs.fuelGal * inputs.fuelWeightPerGal
        items.append(LoadItem(label: "Fuel (\(formatGal(inputs.fuelGal)) gal)",
                              weight: fuelWeight, arm: inputs.fuelArm))
        return items
    }

    // MARK: - Scenarios

    /// Returns the fuel (gal) present in each scenario, floored at zero.
    static func fuelForScenario(_ scenario: Scenario, _ inputs: FlightInputs) -> Double {
        switch scenario {
        case .ramp:     return max(0, inputs.fuelGal)
        case .takeoff:  return max(0, inputs.fuelGal - inputs.taxiBurnGal)
        case .landing:  return max(0, inputs.fuelGal - inputs.taxiBurnGal - inputs.plannedBurnGal)
        case .zeroFuel: return 0
        }
    }

    /// The weight limit (lb) that applies to a scenario; 0 means N/A.
    static func weightLimit(_ scenario: Scenario, _ inputs: FlightInputs) -> Double {
        switch scenario {
        case .ramp:     return inputs.maxRampWeight
        case .takeoff:  return inputs.maxTakeoffWeight
        case .landing:  return inputs.maxLandingWeight
        case .zeroFuel: return inputs.maxZeroFuelWeight
        }
    }

    /// Computes every scenario plus the takeoff allowable-CG range.
    static func evaluate(_ inputs: FlightInputs) -> FlightResult {
        var results: [ScenarioResult] = []

        for scenario in Scenario.allCases {
            let fuel = fuelForScenario(scenario, inputs)
            let point = summarize(
                emptyWeight: inputs.emptyWeight, emptyArm: inputs.emptyArm,
                loads: inputs.loads,
                fuelGal: fuel, fuelArm: inputs.fuelArm,
                fuelWeightPerGal: inputs.fuelWeightPerGal
            )
            let limit = weightLimit(scenario, inputs)
            // A limit of 0 means "not applicable" → no weight failure on that axis.
            let withinWeight = limit <= 0 ? true : point.weight <= limit + 0.001
            let inside = pointInPolygon(cg: point.cg, weight: point.weight,
                                        polygon: inputs.envelope)
            results.append(ScenarioResult(
                scenario: scenario, point: point, fuelGal: fuel,
                withinEnvelope: inside, withinWeightLimit: withinWeight,
                weightLimit: limit
            ))
        }

        let takeoffPoint = results.first(where: { $0.scenario == .takeoff })?.point
        let range = takeoffPoint.flatMap {
            allowableCGRange(atWeight: $0.weight, polygon: inputs.envelope)
        }

        return FlightResult(
            items: breakdown(inputs),
            scenarios: results,
            allowableCGRange: range
        )
    }

    // MARK: - Geometry

    /// Ray-casting point-in-polygon test. The polygon is the CG envelope with
    /// x = cg, y = weight. Points exactly on an edge are treated as inside.
    static func pointInPolygon(cg: Double, weight: Double, polygon: [EnvelopeVertex]) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }

        // On-edge tolerance check first so boundary points count as inside.
        for i in 0..<n {
            let a = polygon[i]
            let b = polygon[(i + 1) % n]
            if isOnSegment(px: cg, py: weight,
                           ax: a.cg, ay: a.weight, bx: b.cg, by: b.weight) {
                return true
            }
        }

        var inside = false
        var j = n - 1
        for i in 0..<n {
            let xi = polygon[i].cg, yi = polygon[i].weight
            let xj = polygon[j].cg, yj = polygon[j].weight
            let denom = yj - yi
            // Guard against a horizontal edge causing division by zero.
            if (yi > weight) != (yj > weight), denom != 0 {
                let xCross = (xj - xi) * (weight - yi) / denom + xi
                if cg < xCross { inside.toggle() }
            }
            j = i
        }
        return inside
    }

    /// True if point P lies on segment AB (within a small tolerance).
    private static func isOnSegment(px: Double, py: Double,
                                    ax: Double, ay: Double,
                                    bx: Double, by: Double) -> Bool {
        let cross = (px - ax) * (by - ay) - (py - ay) * (bx - ax)
        if abs(cross) > 0.01 { return false }
        let minX = min(ax, bx) - 0.01, maxX = max(ax, bx) + 0.01
        let minY = min(ay, by) - 0.01, maxY = max(ay, by) + 0.01
        return px >= minX && px <= maxX && py >= minY && py <= maxY
    }

    /// Interpolates the min/max allowable CG at a given weight by scanning the
    /// polygon edges that cross that weight. Returns nil if none cross.
    static func allowableCGRange(atWeight weight: Double, polygon: [EnvelopeVertex]) -> ClosedRange<Double>? {
        let n = polygon.count
        guard n >= 3 else { return nil }
        var crossings: [Double] = []
        var j = n - 1
        for i in 0..<n {
            let yi = polygon[i].weight, yj = polygon[j].weight
            let xi = polygon[i].cg, xj = polygon[j].cg
            let denom = yj - yi
            if (yi <= weight && yj >= weight) || (yj <= weight && yi >= weight) {
                if denom == 0 {
                    // Horizontal edge exactly at this weight → both ends count.
                    if abs(yi - weight) < 0.001 {
                        crossings.append(xi); crossings.append(xj)
                    }
                } else {
                    let x = xi + (xj - xi) * (weight - yi) / denom
                    crossings.append(x)
                }
            }
            j = i
        }
        guard let lo = crossings.min(), let hi = crossings.max(), lo <= hi else { return nil }
        return lo...hi
    }

    // MARK: - Density altitude

    /// Density-altitude computation. All guards are caller-safe; nonsensical
    /// inputs simply produce a finite number rather than throwing.
    /// - Returns: (pressureAltitudeFt, densityAltitudeFt)
    static func densityAltitude(fieldElevFt: Double, altimeterInHg: Double, oatC: Double) -> (pressureAlt: Double, densityAlt: Double) {
        let pressureAlt = fieldElevFt + (29.92 - altimeterInHg) * 1000
        let isaTemp = 15 - 2 * (pressureAlt / 1000)
        let densityAlt = pressureAlt + 120 * (oatC - isaTemp)
        return (pressureAlt, densityAlt)
    }

    // MARK: - Ad-hoc CG (Tools tab)

    /// Sums ad-hoc (weight, arm) rows into a total weight & CG (guarded).
    static func adHocCG(rows: [(weight: Double, arm: Double)]) -> Point {
        var totalWeight = 0.0
        var totalMoment = 0.0
        for row in rows {
            totalWeight += row.weight
            totalMoment += moment(weight: row.weight, arm: row.arm)
        }
        let cg = totalWeight > 0 ? totalMoment / totalWeight : 0
        return Point(weight: totalWeight, cg: cg)
    }

    // MARK: - Formatting helpers

    private static func formatGal(_ gal: Double) -> String {
        String(format: gal == gal.rounded() ? "%.0f" : "%.1f", gal)
    }
}
