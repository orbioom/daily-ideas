import CoreGraphics
import SwiftUI

/// Pure geometry helpers used for hit-testing and rendering coloring regions.
/// All polygon coordinates are normalized (0...1) in the page's design space and
/// scaled to the rendered canvas at draw / hit-test time.
enum Geometry {

    /// Ray-casting point-in-polygon test. `polygon` is a list of vertices in any
    /// coordinate space; `point` must be in the same space. Returns false for
    /// degenerate polygons (fewer than 3 points) so callers stay crash-safe.
    static func contains(polygon: [CGPoint], point p: CGPoint) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }
        var inside = false
        var j = n - 1
        for i in 0..<n {
            let vi = polygon[i]
            let vj = polygon[j]
            // Does the horizontal ray from p cross the edge (vj -> vi)?
            let crosses = (vi.y > p.y) != (vj.y > p.y)
            if crosses {
                let dy = vi.y - vj.y
                // dy is non-zero whenever `crosses` is true, but guard anyway.
                if dy != 0 {
                    let xCross = (vj.x - vi.x) * (p.y - vi.y) / dy + vi.x
                    if p.x < xCross { inside.toggle() }
                }
            }
            j = i
        }
        return inside
    }

    /// Scale a normalized polygon into a rect of the given size (with optional origin).
    static func scaled(_ polygon: [CGPoint], to size: CGSize, origin: CGPoint = .zero) -> [CGPoint] {
        polygon.map { CGPoint(x: origin.x + $0.x * size.width, y: origin.y + $0.y * size.height) }
    }

    /// Axis-aligned centroid (average of vertices) of a polygon, in its own space.
    /// Used to position by-number labels. Returns the rect center for empty input.
    static func centroid(_ polygon: [CGPoint]) -> CGPoint {
        guard !polygon.isEmpty else { return CGPoint(x: 0.5, y: 0.5) }
        var sx: CGFloat = 0, sy: CGFloat = 0
        for v in polygon { sx += v.x; sy += v.y }
        let c = CGFloat(polygon.count)
        return CGPoint(x: sx / c, y: sy / c)
    }

    /// Build a closed Path from a polygon of points. Empty/short input yields an empty path.
    static func path(_ polygon: [CGPoint]) -> Path {
        var path = Path()
        guard let first = polygon.first, polygon.count >= 2 else { return path }
        path.move(to: first)
        for v in polygon.dropFirst() { path.addLine(to: v) }
        path.closeSubpath()
        return path
    }

    /// Convert polar to cartesian within a unit space centered at `center`.
    /// `radius` and `center` are in normalized 0...1 units. Angle in radians.
    static func polar(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    /// A clamped value in 0...1.
    static func clamp01(_ v: CGFloat) -> CGFloat { min(max(v, 0), 1) }
}
