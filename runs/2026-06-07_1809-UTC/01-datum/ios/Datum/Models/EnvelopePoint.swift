import Foundation
import SwiftData

/// One ordered vertex of an aircraft's CG envelope polygon. The vertices, in
/// order, trace the perimeter of the allowable weight/CG region.
@Model
final class EnvelopePoint {
    var id: UUID = UUID()
    var cgArm: Double = 0   // inches (x axis)
    var weight: Double = 0  // pounds (y axis)
    var order: Int = 0
    var aircraft: Aircraft?

    init(
        id: UUID = UUID(),
        cgArm: Double = 0,
        weight: Double = 0,
        order: Int = 0,
        aircraft: Aircraft? = nil
    ) {
        self.id = id
        self.cgArm = cgArm
        self.weight = weight
        self.order = order
        self.aircraft = aircraft
    }
}
