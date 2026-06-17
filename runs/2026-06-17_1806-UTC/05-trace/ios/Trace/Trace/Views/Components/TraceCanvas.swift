import SwiftUI

/// The drawing surface: renders the glyph guide (road + directional dots/arrows
/// + start marker) and the child's live ink, capturing touches via DragGesture.
/// Works with finger and Apple Pencil (both deliver drag events).
struct TraceCanvas: View {
    @Bindable var session: TracingSession
    let guideStyle: GuideStyle
    let inkColor: Color
    /// When true, dot-number badges sit on the right of each dot so a
    /// left hand resting on the screen doesn't cover them.
    let leftHanded: Bool
    /// Called when the child lifts after drawing a stroke.
    let onStrokeEnded: () -> Void

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Guide layer.
                Canvas { context, _ in
                    drawGuide(context: context, size: size)
                }
                // Ink layer (separate Canvas keeps redraws cheap-ish).
                Canvas { context, _ in
                    drawInk(context: context, size: size)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let norm = normalize(value.location, in: size)
                        if session.liveStroke.isEmpty {
                            session.beginStroke(at: norm)
                        } else {
                            session.appendPoint(norm)
                        }
                    }
                    .onEnded { _ in
                        onStrokeEnded()
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("Tracing area for \(session.glyph.label)")
            .accessibilityHint("Drag along the guide with your finger or Apple Pencil")
        }
    }

    // MARK: - Coordinate helpers

    private func normalize(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let w = max(1, size.width)
        let h = max(1, size.height)
        return CGPoint(x: point.x / w, y: point.y / h)
    }

    private func denorm(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    // MARK: - Drawing

    private func drawGuide(context: GraphicsContext, size: CGSize) {
        for (index, stroke) in session.glyph.strokes.enumerated() {
            let pts = stroke.points.map { denorm($0, in: size) }
            guard pts.count > 1 else { continue }
            let isActive = index == session.currentStrokeIndex && !session.finished
            let isDone = session.completedStrokes.contains(index)

            var path = Path()
            path.move(to: pts[0])
            for p in pts.dropFirst() { path.addLine(to: p) }

            // The "road" — soft wide band along the path.
            let roadColor: Color = isDone ? Theme.good.opacity(0.30) : (isActive ? Theme.accentSoft : Theme.hairline)
            context.stroke(
                path,
                with: .color(roadColor),
                style: StrokeStyle(lineWidth: roadWidth(size), lineCap: .round, lineJoin: .round)
            )
            // A dashed center line to suggest direction.
            if guideStyle == .road {
                context.stroke(
                    path,
                    with: .color(isActive ? Theme.accent.opacity(0.5) : Theme.inkSoft.opacity(0.3)),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12])
                )
            }

            // Directional markers only for the active (or completed) stroke.
            if guideStyle != .road, isActive || isDone {
                drawMarkers(context: context, points: pts, active: isActive)
            }

            // Start marker.
            if isActive, let first = pts.first {
                drawStartMarker(context: context, at: first, next: pts.count > 1 ? pts[1] : first)
            }
        }
    }

    private func drawMarkers(context: GraphicsContext, points: [CGPoint], active: Bool) {
        // Evenly sample along the polyline for dot/arrow placement.
        let sampled = TracingScorer.sample(points.map { CGPoint(x: $0.x, y: $0.y) }, step: 26)
        let color = active ? Theme.accent : Theme.good
        var number = 1
        let stride = max(1, sampled.count / 8)
        var i = 0
        while i < sampled.count {
            let pt = sampled[i]
            if guideStyle == .dots {
                let dotRect = CGRect(x: pt.x - 7, y: pt.y - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: dotRect), with: .color(color.opacity(0.9)))
                if active {
                    let text = Text("\(number)").font(Theme.rounded(11, .bold)).foregroundStyle(.white)
                    let badgeOffset: CGFloat = leftHanded ? 16 : 0
                    context.draw(text, at: CGPoint(x: pt.x + badgeOffset, y: pt.y))
                }
            } else if guideStyle == .arrows, i + stride < sampled.count {
                drawArrow(context: context, from: pt, to: sampled[min(i + stride, sampled.count - 1)], color: color)
            }
            number += 1
            i += stride
        }
    }

    private func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let len: CGFloat = 9
        let wing: CGFloat = 0.5
        var path = Path()
        path.move(to: to)
        path.addLine(to: CGPoint(x: to.x - len * cos(angle - wing), y: to.y - len * sin(angle - wing)))
        path.move(to: to)
        path.addLine(to: CGPoint(x: to.x - len * cos(angle + wing), y: to.y - len * sin(angle + wing)))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func drawStartMarker(context: GraphicsContext, at point: CGPoint, next: CGPoint) {
        // Pulsing-look ring + dot to say "start here".
        let outer = CGRect(x: point.x - 16, y: point.y - 16, width: 32, height: 32)
        context.stroke(Path(ellipseIn: outer), with: .color(Theme.accent), style: StrokeStyle(lineWidth: 3))
        let inner = CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
        context.fill(Path(ellipseIn: inner), with: .color(Theme.accent))
    }

    private func drawInk(context: GraphicsContext, size: CGSize) {
        // Completed strokes.
        for stroke in session.userStrokes where stroke.count > 1 {
            strokeInk(context: context, points: stroke, size: size, opacity: 0.85)
        }
        // Live stroke.
        if session.liveStroke.count > 1 {
            strokeInk(context: context, points: session.liveStroke, size: size, opacity: 1)
        }
    }

    private func strokeInk(context: GraphicsContext, points: [CGPoint], size: CGSize, opacity: Double) {
        let pts = points.map { denorm($0, in: size) }
        guard pts.count > 1 else { return }
        var path = Path()
        path.move(to: pts[0])
        for p in pts.dropFirst() { path.addLine(to: p) }
        context.stroke(
            path,
            with: .color(inkColor.opacity(opacity)),
            style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
        )
    }

    private func roadWidth(_ size: CGSize) -> CGFloat {
        max(24, min(size.width, size.height) * 0.085)
    }
}
