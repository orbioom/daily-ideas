import CoreGraphics
import Foundation

/// Projects horizontal coordinates (alt/az) onto a unit disc for the chart.
/// Zenith → centre, horizon → rim. A stereographic-style azimuthal projection.
struct SkyProjection {
    /// Viewing azimuth the chart is rotated to (the direction at the top of screen).
    var headingAzimuth: Double
    /// Zoom factor (1 = full hemisphere fits the disc).
    var zoom: Double

    init(headingAzimuth: Double = 0, zoom: Double = 1) {
        self.headingAzimuth = headingAzimuth
        self.zoom = max(0.5, min(4.0, zoom))
    }

    /// Returns a normalised point in the unit disc (radius ≤ ~1) for an alt/az,
    /// or nil if the body is below the horizon (and should not be drawn).
    /// Coordinate space: centre (0,0), +x right, +y up.
    func project(altitude: Double, azimuth: Double) -> CGPoint? {
        guard altitude > -1.0 else { return nil }
        // Radial distance from zenith: 0 at zenith (alt 90), 1 at horizon (alt 0).
        let zenithDistance = (90.0 - altitude) / 90.0
        let r = zenithDistance * zoom
        // Rotate azimuth so headingAzimuth is at the top of the disc.
        let theta = AstroMath.rad(azimuth - headingAzimuth)
        // Screen up = the heading direction; +x to the right (east of heading).
        let x = r * sin(theta)
        let y = r * cos(theta)
        return CGPoint(x: x, y: y)
    }

    /// Convert a unit-disc point into a view point given a rect.
    static func viewPoint(_ unit: CGPoint, in rect: CGRect) -> CGPoint {
        let radius = min(rect.width, rect.height) / 2
        let cx = rect.midX
        let cy = rect.midY
        return CGPoint(x: cx + unit.x * radius, y: cy - unit.y * radius)
    }
}
