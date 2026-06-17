import CoreGraphics
import Observation
import SwiftUI

/// Drives one tracing attempt of a glyph: tracks the current stroke, the user's
/// captured polylines (normalized), and produces a score on completion.
@Observable
@MainActor
final class TracingSession {
    let glyph: Glyph

    /// Index of the stroke the child is currently working on.
    private(set) var currentStrokeIndex = 0
    /// Completed user strokes (normalized points), one per target stroke index.
    private(set) var userStrokes: [[CGPoint]]
    /// The in-progress drawn polyline (normalized) for the active stroke.
    private(set) var liveStroke: [CGPoint] = []
    /// Strokes the child has marked complete (adequately covered).
    private(set) var completedStrokes: Set<Int> = []

    private(set) var lastResult: TracingScorer.Result?
    private(set) var finished = false

    init(glyph: Glyph) {
        self.glyph = glyph
        self.userStrokes = Array(repeating: [], count: glyph.strokes.count)
    }

    var totalStrokes: Int { glyph.strokes.count }
    var allStrokesDone: Bool { completedStrokes.count >= totalStrokes }

    /// Target points (normalized) for the active stroke.
    var activeTargetPoints: [CGPoint] {
        guard glyph.strokes.indices.contains(currentStrokeIndex) else { return [] }
        return glyph.strokes[currentStrokeIndex].points
    }

    /// Begin a new live stroke.
    func beginStroke(at point: CGPoint) {
        liveStroke = [clamp(point)]
    }

    /// Append a point to the live stroke.
    func appendPoint(_ point: CGPoint) {
        liveStroke.append(clamp(point))
    }

    /// End the live stroke: store it, evaluate coverage, advance if good enough.
    /// `noFail` forces the stroke to count regardless of coverage.
    func endStroke(noFail: Bool) {
        guard !liveStroke.isEmpty, glyph.strokes.indices.contains(currentStrokeIndex) else {
            liveStroke = []
            return
        }
        // Merge into the slot (replace, taking the better attempt by coverage).
        let target = activeTargetPoints
        let result = TracingScorer.score(target: target, user: liveStroke)
        let prev = userStrokes[currentStrokeIndex]
        let prevResult = prev.isEmpty ? TracingScorer.Result.zero : TracingScorer.score(target: target, user: prev)
        if result.coverage >= prevResult.coverage {
            userStrokes[currentStrokeIndex] = liveStroke
        }
        liveStroke = []

        let bestCoverage = max(result.coverage, prevResult.coverage)
        if noFail || bestCoverage >= 0.55 {
            completedStrokes.insert(currentStrokeIndex)
            advanceToNextIncompleteStroke()
        }
    }

    /// Move the active index to the next stroke not yet completed.
    private func advanceToNextIncompleteStroke() {
        for i in 0..<totalStrokes where !completedStrokes.contains(i) {
            currentStrokeIndex = i
            return
        }
        // All done — keep index at last stroke.
        currentStrokeIndex = max(0, totalStrokes - 1)
    }

    /// Compute the final glyph score from all captured strokes.
    func finalize(noFail: Bool) -> TracingScorer.Result {
        let targets = glyph.strokes.map { $0.points }
        var result = TracingScorer.scoreGlyph(targets: targets, userStrokes: userStrokes)
        if noFail {
            // No-fail mode guarantees at least one star for completing the trace.
            let stars = max(1, result.stars)
            result = TracingScorer.Result(
                coverage: result.coverage,
                accuracy: result.accuracy,
                score: max(result.score, 0.5),
                stars: stars
            )
        }
        lastResult = result
        finished = true
        return result
    }

    /// Reset everything for another attempt at the same glyph.
    func reset() {
        currentStrokeIndex = 0
        userStrokes = Array(repeating: [], count: glyph.strokes.count)
        liveStroke = []
        completedStrokes = []
        lastResult = nil
        finished = false
    }

    private func clamp(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(1, max(0, p.x)), y: min(1, max(0, p.y)))
    }
}
