import SwiftUI

/// The pannable sky chart. Projects the visible hemisphere onto a disc and
/// plots stars, planets, the Moon, the Sun and (optionally) constellation lines.
struct SkyChartCanvas: View {
    let snapshot: SkySnapshot
    let showConstellations: Bool
    let showLabels: Bool
    let isPro: Bool
    /// Heading the top of the chart faces (degrees from North).
    @Binding var heading: Double
    @Binding var zoom: Double
    /// Called when the user taps near a plotted object.
    let onTapObject: (SkyObject) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragStartHeading: Double?
    @State private var pinchStartZoom: Double?

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            let projection = SkyProjection(headingAzimuth: heading, zoom: zoom)
            let plotted = plottedPoints(in: rect, projection: projection)

            ZStack {
                chartCanvas(rect: rect, projection: projection, plotted: plotted)
                cardinalLabels(rect: rect)
                if showLabels {
                    labelOverlay(plotted: plotted)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(rect: rect))
            .gesture(magnifyGesture)
            .onTapGesture(coordinateSpace: .local) { location in
                handleTap(at: location, plotted: plotted)
            }
            .accessibilityElement()
            .accessibilityLabel("Interactive sky chart facing \(HorizontalCoord(altitude: 0, azimuth: heading).compass16). \(plotted.count) objects above the horizon. The Tonight tab lists every object as text.")
        }
    }

    // MARK: - Canvas drawing

    private func chartCanvas(rect: CGRect, projection: SkyProjection, plotted: [PlottedObject]) -> some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let discRect = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
            let disc = Path(ellipseIn: discRect)

            // Sky disc gradient.
            ctx.fill(disc, with: .radialGradient(
                Gradient(colors: [Color(hex: 0x0C1838), Color(hex: 0x05070F)]),
                center: center, startRadius: 0, endRadius: r))
            ctx.stroke(disc, with: .color(Color(hex: 0x35507F)), lineWidth: 1.2)

            // Altitude rings at 30° and 60°.
            ctx.clip(to: disc)
            for altRing in [30.0, 60.0] {
                let ringR = r * (90 - altRing) / 90 * projection.zoom
                if ringR > 2 && ringR < r {
                    let rr = CGRect(x: center.x - ringR, y: center.y - ringR, width: 2 * ringR, height: 2 * ringR)
                    ctx.stroke(Path(ellipseIn: rr), with: .color(Color(hex: 0x223152).opacity(0.7)), lineWidth: 0.5)
                }
            }
            // Cardinal cross.
            var cross = Path()
            cross.move(to: CGPoint(x: center.x - r, y: center.y)); cross.addLine(to: CGPoint(x: center.x + r, y: center.y))
            cross.move(to: CGPoint(x: center.x, y: center.y - r)); cross.addLine(to: CGPoint(x: center.x, y: center.y + r))
            ctx.stroke(cross, with: .color(Color(hex: 0x1B2840).opacity(0.6)), lineWidth: 0.5)

            // Constellation lines.
            if showConstellations {
                drawConstellations(ctx: ctx, rect: rect, projection: projection)
            }

            // Plotted bodies.
            for p in plotted {
                drawObject(ctx: ctx, p: p)
            }
        }
    }

    private func drawConstellations(ctx: GraphicsContext, rect: CGRect, projection: SkyProjection) {
        let lst = JulianDate.lmstHours(from: snapshot.context.date, longitudeEast: snapshot.context.longitude)
        let lat = snapshot.context.latitude
        let allowed = isPro ? Catalog.constellations : Array(Catalog.constellations.prefix(5))
        for con in allowed {
            for (a, b) in con.segments {
                guard let sa = Catalog.starByID[a], let sb = Catalog.starByID[b] else { continue }
                let ha = CoordTransform.equatorialToHorizontal(sa.equatorial, lstHours: lst, latitude: lat)
                let hb = CoordTransform.equatorialToHorizontal(sb.equatorial, lstHours: lst, latitude: lat)
                guard let pa = projection.project(altitude: ha.altitude, azimuth: ha.azimuth),
                      let pb = projection.project(altitude: hb.altitude, azimuth: hb.azimuth) else { continue }
                let va = SkyProjection.viewPoint(pa, in: rect)
                let vb = SkyProjection.viewPoint(pb, in: rect)
                var line = Path()
                line.move(to: va); line.addLine(to: vb)
                ctx.stroke(line, with: .color(Theme.accent.opacity(0.32)), lineWidth: 0.7)
            }
        }
    }

    private func drawObject(ctx: GraphicsContext, p: PlottedObject) {
        let o = p.object
        let pt = p.point
        switch o.kind {
        case .star:
            let radius = starRadius(for: o.magnitude)
            let glow = CGRect(x: pt.x - radius * 2, y: pt.y - radius * 2, width: radius * 4, height: radius * 4)
            ctx.fill(Path(ellipseIn: glow), with: .color(o.tint.opacity(0.12)))
            let dot = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: dot), with: .color(o.tint))
        case .planet:
            let radius: CGFloat = 5
            let halo = CGRect(x: pt.x - radius * 2.2, y: pt.y - radius * 2.2, width: radius * 4.4, height: radius * 4.4)
            ctx.fill(Path(ellipseIn: halo), with: .color(o.tint.opacity(0.22)))
            let dot = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: dot), with: .color(o.tint))
            ctx.stroke(Path(ellipseIn: dot), with: .color(.white.opacity(0.5)), lineWidth: 0.6)
        case .moon:
            let radius: CGFloat = 9
            let dot = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0x2A3045)))
            // Lit portion based on illumination.
            let frac = snapshot.moonPhase.illumination
            if frac > 0.05 {
                let litR = radius * CGFloat(0.5 + 0.5 * frac)
                let litRect = CGRect(x: pt.x - litR, y: pt.y - litR, width: litR * 2, height: litR * 2)
                ctx.fill(Path(ellipseIn: litRect), with: .color(Color(hex: 0xF3EFD8).opacity(0.85)))
            }
            ctx.stroke(Path(ellipseIn: dot), with: .color(Theme.gold.opacity(0.7)), lineWidth: 0.8)
        case .sun:
            let radius: CGFloat = 11
            let halo = CGRect(x: pt.x - radius * 1.8, y: pt.y - radius * 1.8, width: radius * 3.6, height: radius * 3.6)
            ctx.fill(Path(ellipseIn: halo), with: .color(Color(hex: 0xFFD24A).opacity(0.3)))
            let dot = CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2)
            ctx.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0xFFD24A)))
        }
    }

    // MARK: - Labels overlay (SwiftUI text for crispness & Dynamic Type)

    private func labelOverlay(plotted: [PlottedObject]) -> some View {
        ForEach(plotted.filter { labelWorthy($0.object) }) { p in
            Text(p.object.name)
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(p.object.tint.opacity(0.95))
                .shadow(color: .black.opacity(0.8), radius: 2)
                .position(x: p.point.x, y: p.point.y - 16)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func cardinalLabels(rect: CGRect) -> some View {
        let r = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let dirs: [(String, Double)] = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
        return ForEach(dirs, id: \.0) { name, az in
            let theta = AstroMath.rad(az - heading)
            let x = center.x + (r - 14) * sin(theta)
            let y = center.y - (r - 14) * cos(theta)
            Text(name)
                .font(Theme.rounded(13, .heavy))
                .foregroundStyle(name == "N" ? Theme.gold : Theme.inkSoft)
                .position(x: x, y: y)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Projection / hit testing

    struct PlottedObject: Identifiable {
        let id: String
        let object: SkyObject
        let point: CGPoint
    }

    private func plottedPoints(in rect: CGRect, projection: SkyProjection) -> [PlottedObject] {
        var result: [PlottedObject] = []
        let all = snapshot.planets + snapshot.stars
        for o in all {
            if let pt = projectView(o, rect: rect, projection: projection) {
                result.append(PlottedObject(id: o.id, object: o, point: pt))
            }
        }
        return result
    }

    private func projectView(_ o: SkyObject, rect: CGRect, projection: SkyProjection) -> CGPoint? {
        guard o.isAboveHorizon else { return nil }
        guard let unit = projection.project(altitude: o.horizontal.altitude, azimuth: o.horizontal.azimuth) else { return nil }
        // Reject anything projected outside the disc.
        let mag = sqrt(unit.x * unit.x + unit.y * unit.y)
        guard mag <= 1.02 else { return nil }
        return SkyProjection.viewPoint(unit, in: rect)
    }

    private func handleTap(at location: CGPoint, plotted: [PlottedObject]) {
        // Find the nearest plotted object within a touch radius.
        var nearest: PlottedObject?
        var nearestDistance = CGFloat.greatestFiniteMagnitude
        for p in plotted {
            let dx = p.point.x - location.x
            let dy = p.point.y - location.y
            let d = sqrt(dx * dx + dy * dy)
            if d < 28 && d < nearestDistance {
                nearestDistance = d
                nearest = p
            }
        }
        if let nearest {
            onTapObject(nearest.object)
        }
    }

    private func labelWorthy(_ o: SkyObject) -> Bool {
        switch o.kind {
        case .planet, .moon, .sun: return true
        case .star: return o.magnitude < 1.6
        }
    }

    private func starRadius(for magnitude: Double) -> CGFloat {
        // Brighter (lower mag) → bigger. Clamp to a sensible range.
        let v = 4.2 - magnitude * 0.85
        return CGFloat(min(5.0, max(0.9, v)))
    }

    // MARK: - Gestures

    private func dragGesture(rect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStartHeading == nil { dragStartHeading = heading }
                // Horizontal drag rotates the heading.
                let delta = Double(value.translation.width) * 0.35
                heading = AstroMath.normalize360((dragStartHeading ?? heading) - delta)
            }
            .onEnded { _ in dragStartHeading = nil }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                if pinchStartZoom == nil { pinchStartZoom = zoom }
                zoom = min(4.0, max(0.6, (pinchStartZoom ?? zoom) * value.magnification))
            }
            .onEnded { _ in pinchStartZoom = nil }
    }
}
