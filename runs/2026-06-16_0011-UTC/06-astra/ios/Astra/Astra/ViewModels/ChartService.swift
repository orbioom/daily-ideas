import Foundation

/// Bridges a stored `Profile` to a computed `Chart` (and caches per-id within a render pass
/// is unnecessary — computation is sub-millisecond). All math lives in `Ephemeris`.
enum ChartService {

    /// Convert a profile's stored UTC `birthDate` + tz offset into the true UTC instant.
    /// `birthDate` is stored as UTC already (the editor converts local birth time using the
    /// city/manual offset), so we use it directly.
    static func chart(for profile: Profile) -> Chart {
        Ephemeris.chart(utcDate: profile.birthDate,
                        latitude: profile.latitude,
                        longitude: profile.longitude,
                        hasTime: profile.hasExactTime)
    }

    /// A short "Sun · Moon · Rising" headline string for a profile.
    static func bigThree(for profile: Profile) -> (sun: ZodiacSign, moon: ZodiacSign, rising: ZodiacSign?) {
        let chart = chart(for: profile)
        let sun = chart.position(.sun)?.sign ?? .aries
        let moon = chart.position(.moon)?.sign ?? .aries
        return (sun, moon, chart.ascendantSign)
    }

    /// Format a degree-in-sign as e.g. "14° 32′".
    static func formatDegree(_ degInSign: Double) -> String {
        let clamped = min(max(degInSign, 0), 30)
        let deg = Int(floor(clamped))
        let minutes = Int(floor((clamped - Double(deg)) * 60))
        return "\(deg)\u{00B0} \(minutes)\u{2032}"
    }
}
