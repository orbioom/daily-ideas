import Foundation
import SwiftData

/// A dated bake of a `Formula`: a timeline of steps plus the results once it's out of
/// the oven. The timeline is scheduled either forward from a start time or backward
/// from a target finish time (see `BakersMath.schedule`).
@Model
final class Bake {
    var id: UUID
    var title: String
    var date: Date
    /// Anchor instant for the timeline. Interpreted as a start or a finish depending
    /// on `schedulesFromFinish`.
    var anchorTime: Date
    /// When true the timeline is scheduled backward from `anchorTime` as a target
    /// finish; otherwise forward from `anchorTime` as a start.
    var schedulesFromFinish: Bool
    /// Target total dough weight in grams used when this bake was planned.
    var targetDoughGrams: Double
    /// Number of loaves the dough is divided into.
    var loafCount: Int

    // Results (filled in after the bake).
    var notes: String
    /// Crumb rating 1...5, or 0 when not yet rated.
    var crumbRating: Int
    /// Oven temperature in degrees Celsius (canonical storage; converted for display).
    var ovenTempC: Double
    /// Observed final dough temperature in degrees Celsius, or NaN when not recorded.
    var doughTempC: Double
    var isComplete: Bool
    var createdAt: Date

    /// The formula this bake follows.
    var formula: Formula?

    /// Ordered timeline of steps owned by this bake.
    @Relationship(deleteRule: .cascade, inverse: \BakeStep.bake)
    var steps: [BakeStep]

    init(id: UUID = UUID(),
         title: String,
         date: Date = .now,
         anchorTime: Date = .now,
         schedulesFromFinish: Bool = false,
         targetDoughGrams: Double = 900,
         loafCount: Int = 1,
         notes: String = "",
         crumbRating: Int = 0,
         ovenTempC: Double = 232,
         doughTempC: Double = .nan,
         isComplete: Bool = false,
         createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.date = date
        self.anchorTime = anchorTime
        self.schedulesFromFinish = schedulesFromFinish
        self.targetDoughGrams = targetDoughGrams
        self.loafCount = loafCount
        self.notes = notes
        self.crumbRating = crumbRating
        self.ovenTempC = ovenTempC
        self.doughTempC = doughTempC
        self.isComplete = isComplete
        self.createdAt = createdAt
        self.steps = []
    }

    /// Steps in timeline order.
    var orderedSteps: [BakeStep] {
        steps.sorted { $0.order < $1.order }
    }

    /// Total planned minutes across the timeline (guarded against negatives).
    var totalPlannedMinutes: Int {
        steps.reduce(0) { $0 + max(0, $1.plannedMinutes) }
    }
}
