import CoreGraphics
import Foundation

/// Pure, crash-proof scoring for a tracing attempt. All points are normalized
/// to a 0...1 unit square. Never force-unwraps, never divides by zero.
enum TracingScorer {

    /// Result of scoring one stroke (or a whole glyph).
    struct Result: Equatable {
        let coverage: Double   // 0...1: fraction of target sampled covered by user ink
        let accuracy: Double   // 0...1: fraction of user ink lying near the target path
        let score: Double      // 0...1 combined
        let stars: Int         // 0 (retry) ... 3

        static let zero = Result(coverage: 0, accuracy: 0, score: 0, stars: 0)
    }

    /// Tolerance radius (in normalized units) for "on the path".
    static let tolerance: Double = 0.12

    /// Densify a polyline by inserting points so spacing never exceeds `step`.
    /// Returns at least the original vertices; empty in → empty out.
    static func sample(_ polyline: [CGPoint], step: Double = 0.02) -> [CGPoint] {
        guard polyline.count > 1 else { return polyline }
        guard step > 0 else { return polyline }
        var out: [CGPoint] = []
        for i in 0..<(polyline.count - 1) {
            let a = polyline[i]
            let b = polyline[i + 1]
            let dx = Double(b.x - a.x)
            let dy = Double(b.y - a.y)
            let len = (dx * dx + dy * dy).squareRoot()
            out.append(a)
            guard len > step else { continue }
            let segments = max(1, Int((len / step).rounded()))
            if segments > 1 {
                for s in 1..<segments {
                    let t = Double(s) / Double(segments)
                    out.append(CGPoint(x: a.x + CGFloat(dx * t), y: a.y + CGFloat(dy * t)))
                }
            }
        }
        if let last = polyline.last { out.append(last) }
        return out
    }

    /// Squared distance from point `pt` to segment `a`–`b`.
    private static func distSqToSegment(_ pt: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Double {
        let ax = Double(a.x), ay = Double(a.y)
        let bx = Double(b.x), by = Double(b.y)
        let px = Double(pt.x), py = Double(pt.y)
        let dx = bx - ax, dy = by - ay
        let lenSq = dx * dx + dy * dy
        if lenSq <= 1e-9 {
            let ex = px - ax, ey = py - ay
            return ex * ex + ey * ey
        }
        var t = ((px - ax) * dx + (py - ay) * dy) / lenSq
        t = min(1, max(0, t))
        let cx = ax + t * dx
        let cy = ay + t * dy
        let ex = px - cx, ey = py - cy
        return ex * ex + ey * ey
    }

    /// Minimum distance from a point to a polyline path (its segments).
    private static func minDistToPath(_ pt: CGPoint, path: [CGPoint]) -> Double {
        guard !path.isEmpty else { return .greatestFiniteMagnitude }
        if path.count == 1 {
            let ex = Double(pt.x - path[0].x), ey = Double(pt.y - path[0].y)
            return (ex * ex + ey * ey).squareRoot()
        }
        var best = Double.greatestFiniteMagnitude
        for i in 0..<(path.count - 1) {
            let d = distSqToSegment(pt, path[i], path[i + 1])
            if d < best { best = d }
        }
        return best.squareRoot()
    }

    /// Map a combined score to a star count.
    static func stars(forScore score: Double) -> Int {
        if score >= 0.88 { return 3 }
        if score >= 0.70 { return 2 }
        if score >= 0.50 { return 1 }
        return 0
    }

    /// Score the user's drawn polyline against one target stroke.
    static func score(target: [CGPoint], user: [CGPoint], tolerance: Double = tolerance) -> Result {
        // Crash-proofing: any empty / degenerate input scores zero.
        guard !target.isEmpty, !user.isEmpty, tolerance > 0 else { return .zero }

        let targetSamples = sample(target)
        let userSamples = sample(user)
        guard !targetSamples.isEmpty, !userSamples.isEmpty else { return .zero }

        // Coverage: fraction of target samples with a user point within tolerance.
        var covered = 0
        for tp in targetSamples {
            let d = minDistToPath(tp, path: userSamples)
            if d <= tolerance { covered += 1 }
        }
        let coverage = Double(covered) / Double(targetSamples.count)

        // Accuracy: fraction of user samples lying within tolerance of target path.
        var onPath = 0
        for up in userSamples {
            let d = minDistToPath(up, path: targetSamples)
            if d <= tolerance { onPath += 1 }
        }
        let accuracy = Double(onPath) / Double(userSamples.count)

        // Combine: coverage weighted slightly higher (must actually trace the shape).
        let combined = coverage * 0.6 + accuracy * 0.4
        return Result(coverage: coverage, accuracy: accuracy, score: combined, stars: stars(forScore: combined))
    }

    /// Score a whole glyph from one drawn polyline per stroke (parallel arrays).
    /// Missing strokes contribute zero. Returns the averaged result.
    static func scoreGlyph(targets: [[CGPoint]], userStrokes: [[CGPoint]], tolerance: Double = tolerance) -> Result {
        guard !targets.isEmpty else { return .zero }
        var covSum = 0.0, accSum = 0.0, scoreSum = 0.0
        for (i, target) in targets.enumerated() {
            let user = i < userStrokes.count ? userStrokes[i] : []
            let r = score(target: target, user: user, tolerance: tolerance)
            covSum += r.coverage
            accSum += r.accuracy
            scoreSum += r.score
        }
        let n = Double(targets.count)
        let avgScore = scoreSum / n
        return Result(
            coverage: covSum / n,
            accuracy: accSum / n,
            score: avgScore,
            stars: stars(forScore: avgScore)
        )
    }
}
