import Foundation
import SwiftData

/// A rocket airframe the user has designed. The diameter is the maximum body-tube
/// diameter and serves as the caliber reference for stability. Mass is dry mass
/// (no motor installed). CG and CP are measured from the nose tip in millimetres.
@Model
final class Rocket {
    var id: UUID = UUID()
    var name: String = ""
    /// Maximum body-tube diameter in millimetres (the caliber reference).
    var diameterMm: Double = 24.8
    /// Dry mass in grams, with no motor installed.
    var massGramsDry: Double = 34
    /// Coefficient of drag (dimensionless). Typical hobby rockets are ~0.6.
    var cd: Double = 0.6
    /// Centre of gravity, measured from the nose tip, in millimetres.
    var cgFromNoseMm: Double = 0
    /// Centre of pressure, measured from the nose tip, in millimetres.
    var cpFromNoseMm: Double = 0
    /// Overall length in millimetres.
    var lengthMm: Double = 300
    var notes: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Flight.rocket)
    var flights: [Flight] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        diameterMm: Double = 24.8,
        massGramsDry: Double = 34,
        cd: Double = 0.6,
        cgFromNoseMm: Double = 0,
        cpFromNoseMm: Double = 0,
        lengthMm: Double = 300,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.diameterMm = diameterMm
        self.massGramsDry = massGramsDry
        self.cd = cd
        self.cgFromNoseMm = cgFromNoseMm
        self.cpFromNoseMm = cpFromNoseMm
        self.lengthMm = lengthMm
        self.notes = notes
        self.createdAt = createdAt
    }
}

extension Rocket {
    /// Static stability margin in calibers. Guards against a zero diameter.
    var stabilityCal: Double {
        guard diameterMm > 0 else { return 0 }
        return (cpFromNoseMm - cgFromNoseMm) / diameterMm
    }

    var stability: StabilityStatus { StabilityStatus(caliber: stabilityCal) }
}
