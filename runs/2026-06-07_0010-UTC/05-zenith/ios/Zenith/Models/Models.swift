import Foundation
import SwiftData

/// A telescope in the gear locker.
@Model
final class Telescope {
    var name: String
    var aperture: Double          // mm
    var focalLength: Double       // mm
    var typeRaw: String
    var isPrimary: Bool
    var notes: String

    init(name: String, aperture: Double = 150, focalLength: Double = 1200,
         type: ScopeType = .newtonian, isPrimary: Bool = false, notes: String = "") {
        self.name = name
        self.aperture = aperture
        self.focalLength = focalLength
        self.typeRaw = type.rawValue
        self.isPrimary = isPrimary
        self.notes = notes
    }

    var type: ScopeType { ScopeType(rawValue: typeRaw) ?? .newtonian }
    var focalRatio: Double { Optics.focalRatio(aperture: aperture, focalLength: focalLength) }
    var maxUsefulMag: Double { Optics.maxUsefulMag(aperture: aperture) }
    var minUsefulMag: Double { Optics.minUsefulMag(aperture: aperture) }
    var dawesLimit: Double { Optics.dawesLimit(aperture: aperture) }
    var limitingMagnitude: Double { Optics.limitingMagnitude(aperture: aperture) }
}

/// An eyepiece in the case.
@Model
final class Eyepiece {
    var name: String
    var focalLength: Double        // mm
    var apparentFOV: Double        // degrees
    var brand: String
    var notes: String

    init(name: String, focalLength: Double = 25, apparentFOV: Double = 52,
         brand: String = "", notes: String = "") {
        self.name = name
        self.focalLength = focalLength
        self.apparentFOV = apparentFOV
        self.brand = brand
        self.notes = notes
    }
}

/// An observing-session record.
@Model
final class Observation {
    var date: Date
    var targetName: String
    var targetTypeRaw: String
    var constellation: String
    var telescopeName: String
    var eyepieceName: String
    var magnification: Double
    var location: String
    var bortle: Int                // 1...9 sky brightness
    var seeing: Int                // 1...5 (5 = best)
    var transparency: Int          // 1...5
    var rating: Int                // 1...5 personal rating
    var notes: String

    init(date: Date = .now, targetName: String = "", targetType: TargetType = .galaxy,
         constellation: String = "", telescopeName: String = "", eyepieceName: String = "",
         magnification: Double = 0, location: String = "", bortle: Int = 5,
         seeing: Int = 3, transparency: Int = 3, rating: Int = 3, notes: String = "") {
        self.date = date
        self.targetName = targetName
        self.targetTypeRaw = targetType.rawValue
        self.constellation = constellation
        self.telescopeName = telescopeName
        self.eyepieceName = eyepieceName
        self.magnification = magnification
        self.location = location
        self.bortle = bortle
        self.seeing = seeing
        self.transparency = transparency
        self.rating = rating
        self.notes = notes
    }

    var targetType: TargetType { TargetType(rawValue: targetTypeRaw) ?? .galaxy }
}
