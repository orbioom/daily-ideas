import Foundation
import SwiftData

/// A reusable dive site that owns the dives logged there.
@Model
final class DiveSite {
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Dive.site)
    var dives: [Dive] = []

    init(name: String, location: String = "") {
        self.name = name
        self.location = location
    }
    var diveCount: Int { dives.count }
    var maxDepthM: Double { dives.map(\.maxDepthM).max() ?? 0 }
}

/// A single logged dive.
@Model
final class Dive {
    var id: UUID = UUID()
    var date: Date = Date()
    var maxDepthM: Double = 0
    var avgDepthM: Double = 0          // 0 = unknown; SAC falls back to a square estimate
    var durationMin: Int = 0
    var waterTempC: Double = 0
    var oxygenPercent: Int = 21
    var startPressureBar: Int = 200
    var endPressureBar: Int = 50
    var tankLitres: Double = 12
    var typeRaw: String = DiveType.boat.rawValue
    var buddy: String = ""
    var visibility: String = ""
    var rating: Int = 0               // 0–5
    var notes: String = ""
    var site: DiveSite?

    init(date: Date = Date(), maxDepthM: Double = 0, durationMin: Int = 0) {
        self.date = date
        self.maxDepthM = max(0, maxDepthM)
        self.durationMin = max(0, durationMin)
    }

    var type: DiveType {
        get { DiveType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    var gas: BreathingGas { BreathingGas(oxygenPercent: oxygenPercent) }
    var gasUsedBar: Double { Double(max(0, startPressureBar - endPressureBar)) }
    /// Average depth used for consumption math (logged, else 60% of max — a typical multi-level estimate).
    var effectiveAvgDepth: Double { avgDepthM > 0 ? avgDepthM : maxDepthM * 0.6 }
    var sac: Double {
        DiveMath.sac(gasUsedBar: gasUsedBar, tankLitres: tankLitres,
                     durationMin: Double(durationMin), avgDepthM: effectiveAvgDepth)
    }
    /// ppO2 at the deepest point — flags an exceeded oxygen limit.
    var maxPPO2: Double { DiveMath.ppO2(oxygenPercent: oxygenPercent, atDepth: maxDepthM) }
}
