import Foundation
import SwiftData

/// A knitting or crochet project that owns one or more row/stitch counters
/// and records its own gauge so the gauge tools can pre-fill from it.
@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var craftRaw: String = Craft.knit.rawValue
    var yarn: String = ""
    var tool: String = ""           // needle or hook size, free text
    var gaugeStitches: Double = 0   // stitches per 4 in (10 cm)
    var gaugeRows: Double = 0       // rows per 4 in (10 cm)
    var notes: String = ""
    var statusRaw: String = ProjectStatus.active.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Counter.project)
    var counters: [Counter] = []

    init(name: String, craft: Craft = .knit, yarn: String = "", tool: String = "") {
        self.name = name
        self.craftRaw = craft.rawValue
        self.yarn = yarn
        self.tool = tool
    }

    var craft: Craft {
        get { Craft(rawValue: craftRaw) ?? .knit }
        set { craftRaw = newValue.rawValue }
    }
    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
    var hasGauge: Bool { gaugeStitches > 0 }

    /// Counters in stable display order.
    var orderedCounters: [Counter] {
        counters.sorted { $0.sortIndex < $1.sortIndex }
    }
}
