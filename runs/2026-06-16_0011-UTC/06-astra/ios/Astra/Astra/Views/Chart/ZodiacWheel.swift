import SwiftUI

/// The natal chart wheel, drawn with Canvas: a zodiac ring with sign glyphs,
/// whole-sign house divisions, planet glyphs at their true degrees, and aspect
/// lines across the center. The hero of the app.
///
/// Static under Reduce Motion (no rotation/twinkle); the layout itself is fully
/// deterministic. Tapping a planet glyph reports the planet back to the parent.
struct ZodiacWheel: View {
    let chart: Chart
    let aspects: [AspectHit]
    var onTapPlanet: (Planet) -> Void = { _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Chart longitudes increase counter-clockwise; we anchor the Ascendant (or 0° Aries
    // when no time) to the left (9 o'clock), the astrological convention.
    private var anchorLongitude: Double {
        chart.ascendant ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outer = side / 2 - 4
                let signRingInner = outer * 0.82
                let houseRingInner = outer * 0.62
                let planetRadius = outer * 0.72
                let aspectRadius = houseRingInner

                drawRing(context: context, center: center, outer: outer, inner: signRingInner)
                drawSignDivisions(context: context, center: center, inner: signRingInner, outer: outer)
                drawSignGlyphs(context: context, center: center, radius: (signRingInner + outer) / 2)
                drawHouses(context: context, center: center, inner: houseRingInner, outer: signRingInner)
                drawAspectLines(context: context, center: center, radius: aspectRadius)
                drawPlanets(context: context, center: center, radius: planetRadius, ringInner: houseRingInner)
            }
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .overlay(tapTargets(side: side, container: geo.size))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: Coordinate mapping

    /// Map an ecliptic longitude to a screen angle (radians) with the anchor at 9 o'clock,
    /// increasing counter-clockwise.
    private func screenAngle(for longitude: Double) -> Double {
        // Degrees east of the anchor.
        let rel = AstroMath.norm360(longitude - anchorLongitude)
        // 0 → left (180°); counter-clockwise means subtracting.
        let deg = 180 - rel
        return deg * AstroMath.deg2rad
    }

    private func point(_ center: CGPoint, _ radius: Double, _ angle: Double) -> CGPoint {
        // Screen y grows downward; negate sin so positive angles go up.
        CGPoint(x: center.x + radius * cos(angle),
                y: center.y - radius * sin(angle))
    }

    // MARK: Drawing

    private func drawRing(context: GraphicsContext, center: CGPoint, outer: Double, inner: Double) {
        let outerRect = CGRect(x: center.x - outer, y: center.y - outer, width: outer * 2, height: outer * 2)
        let innerRect = CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)
        context.stroke(Path(ellipseIn: outerRect), with: .color(Theme.accent.opacity(0.5)), lineWidth: 1.5)
        context.stroke(Path(ellipseIn: innerRect), with: .color(Theme.accent.opacity(0.35)), lineWidth: 1)
    }

    private func drawSignDivisions(context: GraphicsContext, center: CGPoint, inner: Double, outer: Double) {
        for s in 0..<12 {
            let lon = Double(s) * 30
            let a = screenAngle(for: lon)
            var path = Path()
            path.move(to: point(center, inner, a))
            path.addLine(to: point(center, outer, a))
            context.stroke(path, with: .color(Theme.hairline), lineWidth: 1)
        }
    }

    private func drawSignGlyphs(context: GraphicsContext, center: CGPoint, radius: Double) {
        for sign in ZodiacSign.allCases {
            let midLon = Double(sign.rawValue) * 30 + 15
            let a = screenAngle(for: midLon)
            let p = point(center, radius, a)
            let text = Text(sign.glyph)
                .font(.system(size: radius * 0.12))
                .foregroundStyle(sign.element.color)
            context.draw(text, at: p)
        }
    }

    private func drawHouses(context: GraphicsContext, center: CGPoint, inner: Double, outer: Double) {
        guard let ascSign = chart.ascendantSign else { return }
        // Whole-sign: each house cusp sits at the start of a sign, beginning with the Ascendant's sign.
        for h in 0..<12 {
            let signIndex = (ascSign.rawValue + h) % 12
            let cuspLon = Double(signIndex) * 30
            let a = screenAngle(for: cuspLon)
            var path = Path()
            path.move(to: point(center, inner, a))
            path.addLine(to: point(center, outer, a))
            let isAngular = (h % 3 == 0)
            context.stroke(path,
                           with: .color(isAngular ? Theme.accent.opacity(0.7) : Theme.hairline),
                           lineWidth: isAngular ? 1.6 : 0.8)

            // House number near the inner ring.
            let labelLon = cuspLon + 15
            let la = screenAngle(for: labelLon)
            let lp = point(center, inner + (outer - inner) * 0.18, la)
            let num = Text("\(h + 1)")
                .font(.system(size: inner * 0.07, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
            context.draw(num, at: lp)
        }
    }

    private func drawAspectLines(context: GraphicsContext, center: CGPoint, radius: Double) {
        for hit in aspects {
            guard let pa = chart.position(hit.a), let pb = chart.position(hit.b) else { continue }
            let a1 = screenAngle(for: pa.longitude)
            let a2 = screenAngle(for: pb.longitude)
            var path = Path()
            path.move(to: point(center, radius, a1))
            path.addLine(to: point(center, radius, a2))
            context.stroke(path, with: .color(hit.kind.color.opacity(0.55)),
                           lineWidth: hit.kind.isChallenging ? 1.0 : 1.2)
        }
    }

    private func drawPlanets(context: GraphicsContext, center: CGPoint, radius: Double, ringInner: Double) {
        // Spread overlapping glyphs slightly by nudging radius for close pairs.
        let sorted = chart.positions.sorted { $0.longitude < $1.longitude }
        var lastAngleDeg: Double = -999
        for pos in sorted {
            var r = radius
            let aDeg = AstroMath.norm360(pos.longitude - anchorLongitude)
            if abs(aDeg - lastAngleDeg) < 7 {
                r = radius - ringInner * 0.18   // pull inward to avoid overlap
            }
            lastAngleDeg = aDeg
            let a = screenAngle(for: pos.longitude)
            let p = point(center, r, a)

            // A small disc behind the glyph for legibility.
            let discR = radius * 0.085
            let discRect = CGRect(x: p.x - discR, y: p.y - discR, width: discR * 2, height: discR * 2)
            context.fill(Path(ellipseIn: discRect), with: .color(Theme.surface))
            context.stroke(Path(ellipseIn: discRect), with: .color(Theme.accent.opacity(0.4)), lineWidth: 1)

            let glyph = Text(pos.planet.glyph)
                .font(.system(size: discR * 1.05))
                .foregroundStyle(pos.retrograde ? Theme.bad : Theme.ink)
            context.draw(glyph, at: p)

            // A tick from the glyph to the natal degree on the inner ring.
            var tick = Path()
            tick.move(to: point(center, ringInner, a))
            tick.addLine(to: point(center, r - discR, a))
            context.stroke(tick, with: .color(Theme.inkFaint.opacity(0.4)), lineWidth: 0.6)
        }
    }

    // MARK: Tap targets

    /// Invisible buttons placed over each planet glyph so taps open the detail sheet.
    private func tapTargets(side: CGFloat, container: CGSize) -> some View {
        let center = CGPoint(x: container.width / 2, y: container.height / 2)
        let outer = side / 2 - 4
        let radius = outer * 0.72
        let ringInner = outer * 0.62
        let sorted = chart.positions.sorted { $0.longitude < $1.longitude }

        return ZStack {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, pos in
                let nudged = idx > 0 && abs(AstroMath.norm360(pos.longitude - anchorLongitude)
                                            - AstroMath.norm360(sorted[idx - 1].longitude - anchorLongitude)) < 7
                let r = nudged ? radius - ringInner * 0.18 : radius
                let a = screenAngle(for: pos.longitude)
                let p = point(center, r, a)
                Button {
                    onTapPlanet(pos.planet)
                } label: {
                    Color.clear.frame(width: 40, height: 40)
                        .contentShape(Circle())
                }
                .position(x: p.x, y: p.y)
                .accessibilityLabel("\(pos.planet.name) in \(pos.sign.name)\(pos.retrograde ? ", retrograde" : "")")
            }
        }
    }

    private var accessibilitySummary: String {
        let parts = chart.positions.map { "\($0.planet.name) in \($0.sign.name)" }
        return "Natal wheel. " + parts.joined(separator: ", ")
    }
}
