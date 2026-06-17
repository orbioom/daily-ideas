import Foundation
import SwiftData

/// A log entry recording how the user's targets evolved over time. Written when
/// the plan is saved and when an adaptive recommendation is applied.
@Model
final class TargetSnapshot {
    @Attribute(.unique) var id: UUID
    var date: Date
    var calorieTarget: Double
    var proteinG: Double
    var carbG: Double
    var fatG: Double
    var estimatedTDEE: Double
    var rationale: String

    init(id: UUID = UUID(),
         date: Date,
         calorieTarget: Double,
         proteinG: Double,
         carbG: Double,
         fatG: Double,
         estimatedTDEE: Double,
         rationale: String) {
        self.id = id
        self.date = date
        self.calorieTarget = calorieTarget
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.estimatedTDEE = estimatedTDEE
        self.rationale = rationale
    }

    var macros: MacroTargets { MacroTargets(proteinG: proteinG, carbG: carbG, fatG: fatG) }
}
