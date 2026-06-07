import Foundation

/// Ceramics math: pyrometric cone temperatures, glaze batch scaling, and firing
/// schedule time/energy estimates.
enum ConeMath {

    struct ConeTemp: Identifiable {
        var id: String { cone }
        let cone: String
        let slowF: Int   // °F at 108 °F/hr
        let fastF: Int   // °F at 270 °F/hr
    }

    /// Approximate Orton self-supporting cone temperatures (°F). For reference
    /// only — always confirm with a current Orton chart and witness cones.
    static let coneTable: [ConeTemp] = [
        ConeTemp(cone: "010", slowF: 1576, fastF: 1636),
        ConeTemp(cone: "09",  slowF: 1605, fastF: 1665),
        ConeTemp(cone: "08",  slowF: 1683, fastF: 1728),
        ConeTemp(cone: "07",  slowF: 1733, fastF: 1789),
        ConeTemp(cone: "06",  slowF: 1798, fastF: 1828),
        ConeTemp(cone: "05",  slowF: 1839, fastF: 1888),
        ConeTemp(cone: "04",  slowF: 1922, fastF: 1945),
        ConeTemp(cone: "03",  slowF: 1953, fastF: 1987),
        ConeTemp(cone: "02",  slowF: 1987, fastF: 2016),
        ConeTemp(cone: "01",  slowF: 2016, fastF: 2046),
        ConeTemp(cone: "1",   slowF: 2043, fastF: 2079),
        ConeTemp(cone: "2",   slowF: 2057, fastF: 2088),
        ConeTemp(cone: "3",   slowF: 2073, fastF: 2106),
        ConeTemp(cone: "4",   slowF: 2120, fastF: 2160),
        ConeTemp(cone: "5",   slowF: 2163, fastF: 2205),
        ConeTemp(cone: "6",   slowF: 2232, fastF: 2269),
        ConeTemp(cone: "7",   slowF: 2262, fastF: 2295),
        ConeTemp(cone: "8",   slowF: 2280, fastF: 2320),
        ConeTemp(cone: "9",   slowF: 2300, fastF: 2336),
        ConeTemp(cone: "10",  slowF: 2345, fastF: 2381)
    ]

    static let coneNames: [String] = coneTable.map { $0.cone }

    static func coneTemp(_ cone: String) -> ConeTemp? {
        coneTable.first { $0.cone == cone }
    }

    /// Peak temperature for a cone at a given final ramp (slow/fast), in °F.
    static func peakF(cone: String, fast: Bool) -> Int? {
        guard let c = coneTemp(cone) else { return nil }
        return fast ? c.fastF : c.slowF
    }

    static func fToC(_ f: Double) -> Double { (f - 32) * 5 / 9 }
    static func cToF(_ c: Double) -> Double { c * 9 / 5 + 32 }

    static func formatTemp(_ fahrenheit: Int, celsius: Bool) -> String {
        celsius ? "\(Int(fToC(Double(fahrenheit)).rounded()))°C" : "\(fahrenheit)°F"
    }

    // MARK: - Glaze batch scaling

    struct BatchLine: Identifiable {
        let id: UUID
        let name: String
        let percentage: Double
        let grams: Double
        let isAddition: Bool
    }

    /// Scales a recipe to a batch size. Base materials are scaled so their grams
    /// total `batchGrams`; additions are scaled relative to the same 100-unit base
    /// (so 2% colorant on a 1000 g base batch = 20 g).
    static func batch(materials: [(name: String, pct: Double, addition: Bool)],
                      batchGrams: Double) -> [BatchLine] {
        let baseTotal = materials.filter { !$0.addition }.map { $0.pct }.reduce(0, +)
        guard baseTotal > 0 else { return [] }
        let factor = batchGrams / baseTotal
        return materials.map { m in
            BatchLine(id: UUID(), name: m.name, percentage: m.pct,
                      grams: m.pct * factor, isAddition: m.addition)
        }
    }

    static func baseTotal(_ materials: [(name: String, pct: Double, addition: Bool)]) -> Double {
        materials.filter { !$0.addition }.map { $0.pct }.reduce(0, +)
    }

    // MARK: - Firing schedule

    struct Segment { let rate: Double; let target: Double; let hold: Double } // rate °/hr (0 = AFAP), target °, hold min

    /// Total firing time (hours) from a start temperature through the segments.
    /// AFAP (rate 0) segments are estimated at a default 9999-equivalent (kiln
    /// max) — represented as a fixed brisk 500°/hr so the estimate is bounded.
    static func totalHours(start: Double, segments: [Segment]) -> Double {
        var current = start
        var hours = 0.0
        for seg in segments {
            let delta = abs(seg.target - current)
            let rate = seg.rate <= 0 ? 500.0 : seg.rate
            hours += delta / rate
            hours += seg.hold / 60.0
            current = seg.target
        }
        return hours
    }

    /// Estimated energy cost = kiln power (kW) × hours × duty factor × price/kWh.
    /// Duty factor ~0.65 reflects that the kiln cycles its elements, not full draw.
    static func estimatedCost(hours: Double, kilnKW: Double, pricePerKWh: Double,
                              dutyFactor: Double = 0.65) -> Double {
        max(0, hours * kilnKW * dutyFactor * pricePerKWh)
    }

    static func formatHours(_ h: Double) -> String {
        let total = Int((h * 60).rounded())
        return "\(total / 60)h \(String(format: "%02d", total % 60))m"
    }
}
