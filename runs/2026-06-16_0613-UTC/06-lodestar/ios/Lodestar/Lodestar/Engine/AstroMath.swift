import Foundation

/// Angle helpers and guarded trig used throughout the astronomy engine.
/// Everything works in degrees unless noted; conversions are explicit.
enum AstroMath {
    static let degToRad = Double.pi / 180.0
    static let radToDeg = 180.0 / Double.pi

    @inline(__always) static func rad(_ deg: Double) -> Double { deg * degToRad }
    @inline(__always) static func deg(_ rad: Double) -> Double { rad * radToDeg }

    @inline(__always) static func sind(_ deg: Double) -> Double { sin(rad(deg)) }
    @inline(__always) static func cosd(_ deg: Double) -> Double { cos(rad(deg)) }
    @inline(__always) static func tand(_ deg: Double) -> Double { tan(rad(deg)) }

    /// Guarded asin — clamps the input to [-1, 1] before the call. Returns degrees.
    @inline(__always) static func asind(_ x: Double) -> Double {
        deg(asin(clampUnit(x)))
    }

    /// Guarded acos — clamps the input to [-1, 1] before the call. Returns degrees.
    @inline(__always) static func acosd(_ x: Double) -> Double {
        deg(acos(clampUnit(x)))
    }

    /// atan2 in degrees, normalised to [0, 360).
    @inline(__always) static func atan2d(_ y: Double, _ x: Double) -> Double {
        normalize360(deg(atan2(y, x)))
    }

    @inline(__always) static func clampUnit(_ x: Double) -> Double {
        if x.isNaN { return 0 }
        return min(1.0, max(-1.0, x))
    }

    /// Normalise an angle in degrees to [0, 360).
    static func normalize360(_ deg: Double) -> Double {
        if !deg.isFinite { return 0 }
        var v = deg.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    /// Normalise an angle in degrees to (-180, 180].
    static func normalize180(_ deg: Double) -> Double {
        var v = normalize360(deg)
        if v > 180 { v -= 360 }
        return v
    }

    /// Normalise hours to [0, 24).
    static func normalize24(_ hours: Double) -> Double {
        if !hours.isFinite { return 0 }
        var v = hours.truncatingRemainder(dividingBy: 24)
        if v < 0 { v += 24 }
        return v
    }
}
