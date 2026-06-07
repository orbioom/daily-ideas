import Foundation
import SwiftData

/// A glaze recipe: a set of materials by percentage plus firing metadata.
@Model
final class Glaze {
    var id: UUID = UUID()
    var name: String = ""
    var coneRange: String = "6"      // e.g. "6" or "5-6"
    var atmosphere: String = "Oxidation"
    var surface: String = "Glossy"   // Glossy / Satin / Matte
    var colorNote: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \GlazeMaterial.glaze)
    var materials: [GlazeMaterial] = []

    init(name: String, coneRange: String = "6", atmosphere: String = "Oxidation",
         surface: String = "Glossy", colorNote: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.coneRange = coneRange
        self.atmosphere = atmosphere
        self.surface = surface
        self.colorNote = colorNote
        self.notes = notes
        self.createdAt = Date()
    }

    var orderedMaterials: [GlazeMaterial] {
        materials.sorted { ($0.isAddition ? 1 : 0, -$0.percentage) < ($1.isAddition ? 1 : 0, -$1.percentage) }
    }
    var baseTotal: Double { materials.filter { !$0.isAddition }.map { $0.percentage }.reduce(0, +) }
}

/// One ingredient in a glaze, by batch percentage.
@Model
final class GlazeMaterial {
    var id: UUID = UUID()
    var name: String = ""
    var percentage: Double = 0
    /// Colorants/opacifiers added on top of the 100-unit base.
    var isAddition: Bool = false
    var glaze: Glaze?

    init(name: String, percentage: Double, isAddition: Bool = false) {
        self.id = UUID()
        self.name = name
        self.percentage = percentage
        self.isAddition = isAddition
    }
}

/// A kiln firing log with a ramp schedule and result.
@Model
final class Firing {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()
    var kind: String = "Glaze"        // Bisque / Glaze
    var targetCone: String = "6"
    var atmosphere: String = "Oxidation"
    var fastRamp: Bool = false        // peak temp uses fast (270°/hr) column
    var startTempF: Double = 70
    var result: String = "Planned"    // Planned / Success / Issues
    var resultNotes: String = ""
    @Relationship(deleteRule: .cascade, inverse: \FiringSegment.firing)
    var segments: [FiringSegment] = []

    init(name: String, date: Date = Date(), kind: String = "Glaze",
         targetCone: String = "6", atmosphere: String = "Oxidation") {
        self.id = UUID()
        self.name = name
        self.date = date
        self.kind = kind
        self.targetCone = targetCone
        self.atmosphere = atmosphere
    }

    var orderedSegments: [FiringSegment] { segments.sorted { $0.order < $1.order } }

    var totalHours: Double {
        ConeMath.totalHours(start: startTempF,
                            segments: orderedSegments.map {
                                ConeMath.Segment(rate: $0.rate, target: $0.targetTempF, hold: $0.holdMinutes)
                            })
    }
    var peakTempF: Double { orderedSegments.map { $0.targetTempF }.max() ?? startTempF }
}

/// One ramp segment: a rate, a target temperature, and a hold.
@Model
final class FiringSegment {
    var id: UUID = UUID()
    var order: Int = 0
    var rate: Double = 0            // °F/hr, 0 = as fast as possible
    var targetTempF: Double = 0
    var holdMinutes: Double = 0
    var firing: Firing?

    init(order: Int, rate: Double, targetTempF: Double, holdMinutes: Double = 0) {
        self.id = UUID()
        self.order = order
        self.rate = rate
        self.targetTempF = targetTempF
        self.holdMinutes = holdMinutes
    }
}

/// A piece moving through the studio workflow.
@Model
final class Piece {
    var id: UUID = UUID()
    var title: String = ""
    var clayBody: String = ""
    var formingMethod: String = "Wheel"   // Wheel / Handbuilt / Slipcast / Other
    var stage: String = "Greenware"        // Greenware / Bisque / Glazed / Fired / Finished
    var glazeName: String = ""
    var heightCm: Double = 0
    var widthCm: Double = 0
    var notes: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String, clayBody: String = "", formingMethod: String = "Wheel",
         stage: String = "Greenware") {
        self.id = UUID()
        self.title = title
        self.clayBody = clayBody
        self.formingMethod = formingMethod
        self.stage = stage
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    static let stages = ["Greenware", "Bisque", "Glazed", "Fired", "Finished"]
}
