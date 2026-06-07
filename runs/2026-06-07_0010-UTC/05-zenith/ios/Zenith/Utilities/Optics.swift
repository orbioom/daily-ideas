import Foundation

enum ScopeType: String, Codable, CaseIterable, Identifiable {
    case refractor, newtonian, dobsonian, sct, maksutov
    var id: String { rawValue }
    var label: String {
        switch self {
        case .refractor: return "Refractor"
        case .newtonian: return "Newtonian"
        case .dobsonian: return "Dobsonian"
        case .sct: return "SCT"
        case .maksutov: return "Maksutov"
        }
    }
}

enum TargetType: String, Codable, CaseIterable, Identifiable {
    case galaxy, nebula, cluster, planet, moon, double, comet
    var id: String { rawValue }
    var label: String {
        switch self {
        case .galaxy: return "Galaxy"; case .nebula: return "Nebula"; case .cluster: return "Star cluster"
        case .planet: return "Planet"; case .moon: return "Moon"; case .double: return "Double star"
        case .comet: return "Comet"
        }
    }
    var symbol: String {
        switch self {
        case .galaxy: return "hurricane"; case .nebula: return "cloud.fog"; case .cluster: return "sparkles"
        case .planet: return "circle.circle"; case .moon: return "moon"; case .double: return "circle.grid.2x1"
        case .comet: return "asterisk"
        }
    }
}

/// A fully computed view through one telescope + eyepiece (+ optional barlow).
struct OpticalView {
    var magnification: Double
    var trueFOVDegrees: Double
    var exitPupilMM: Double
    var fitsLowPower: Bool       // exit pupil within useful range
    var quality: String          // a short read on the combination
}

/// Pure optics. All the math an observer does at the eyepiece by hand.
enum Optics {

    static func focalRatio(aperture: Double, focalLength: Double) -> Double {
        aperture > 0 ? focalLength / aperture : 0
    }

    static func magnification(scopeFL: Double, eyepieceFL: Double, barlow: Double = 1) -> Double {
        eyepieceFL > 0 ? (scopeFL * barlow) / eyepieceFL : 0
    }

    /// True field of view in degrees = apparent FOV / magnification.
    static func trueFOV(apparentFOV: Double, magnification: Double) -> Double {
        magnification > 0 ? apparentFOV / magnification : 0
    }

    /// Exit pupil (mm) = aperture / magnification.
    static func exitPupil(aperture: Double, magnification: Double) -> Double {
        magnification > 0 ? aperture / magnification : 0
    }

    /// Highest useful magnification ≈ 2× aperture in mm (good seeing).
    static func maxUsefulMag(aperture: Double) -> Double { aperture * 2 }

    /// Lowest useful magnification (7mm exit pupil ceiling).
    static func minUsefulMag(aperture: Double) -> Double { aperture / 7 }

    /// Dawes limit in arcseconds — finest resolvable double star.
    static func dawesLimit(aperture: Double) -> Double {
        aperture > 0 ? 116.0 / aperture : 0
    }

    /// Rough limiting visual magnitude for the aperture.
    static func limitingMagnitude(aperture: Double) -> Double {
        guard aperture > 0 else { return 0 }
        return 7.7 + 5 * log10(aperture / 10.0)   // aperture in cm
    }

    /// Compose the full optical view for a combination.
    static func view(scopeFL: Double, aperture: Double,
                     eyepieceFL: Double, apparentFOV: Double,
                     barlow: Double = 1) -> OpticalView {
        let mag = magnification(scopeFL: scopeFL, eyepieceFL: eyepieceFL, barlow: barlow)
        let tfov = trueFOV(apparentFOV: apparentFOV, magnification: mag)
        let exit = exitPupil(aperture: aperture, magnification: mag)
        let maxM = maxUsefulMag(aperture: aperture)
        let minM = minUsefulMag(aperture: aperture)
        let fits = mag >= minM * 0.5 && mag <= maxM

        let quality: String
        if mag > maxM {
            quality = "Over max useful magnification — image will be dim and soft."
        } else if exit > 6.5 {
            quality = "Very low power; some light is wasted past your pupil."
        } else if exit < 0.5 {
            quality = "Very high power; only steady nights will hold this."
        } else if mag >= maxM * 0.7 {
            quality = "High power — great for planets and tight doubles."
        } else if exit >= 2 && exit <= 4 {
            quality = "Ideal deep-sky exit pupil — bright, wide views."
        } else {
            quality = "A versatile, everyday combination."
        }

        return OpticalView(magnification: mag, trueFOVDegrees: tfov, exitPupilMM: exit,
                           fitsLowPower: fits, quality: quality)
    }
}
