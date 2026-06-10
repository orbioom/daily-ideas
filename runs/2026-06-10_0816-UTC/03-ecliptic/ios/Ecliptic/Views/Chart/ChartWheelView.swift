import SwiftUI

/// The chart wheel, drawn in Canvas: zodiac ring with glyphs, planets at
/// their true longitudes, aspect chords, and the ascendant axis. Rotated so
/// the ascendant (or 0° Aries without one) sits at the left, houses running
/// counterclockwise — the classical presentation.
struct ChartWheelView: View {
    let chart: Chart

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let rOuter = min(cx, cy) - 4
            let rInner = rOuter * 0.78
            let rPlanet = rOuter * 0.62
            let rAspect = rOuter * 0.52
            let ascRef = chart.ascendant ?? 0

            func point(_ longitude: Double, _ radius: Double) -> CGPoint {
                let theta = 180 - (longitude - ascRef)
                return CGPoint(x: cx + radius * Astronomy.cosD(theta),
                               y: cy + radius * Astronomy.sinD(theta))
            }

            // Rings
            let ringColor = Color.primary.opacity(0.35)
            context.stroke(Path(ellipseIn: CGRect(x: cx - rOuter, y: cy - rOuter,
                                                  width: rOuter * 2, height: rOuter * 2)),
                           with: .color(ringColor), lineWidth: 1.5)
            context.stroke(Path(ellipseIn: CGRect(x: cx - rInner, y: cy - rInner,
                                                  width: rInner * 2, height: rInner * 2)),
                           with: .color(ringColor.opacity(0.6)), lineWidth: 1)

            // Sign boundaries + glyphs
            for s in 0..<12 {
                let boundary = Double(s) * 30
                var path = Path()
                path.move(to: point(boundary, rInner))
                path.addLine(to: point(boundary, rOuter))
                context.stroke(path, with: .color(ringColor.opacity(0.5)), lineWidth: 1)

                let mid = boundary + 15
                let sign = Sign.at(longitude: mid)
                let glyphPoint = point(mid, (rOuter + rInner) / 2)
                context.draw(
                    Text(sign.glyph)
                        .font(.system(size: rOuter * 0.085))
                        .foregroundStyle(Color.primary.opacity(0.55)),
                    at: glyphPoint
                )
            }

            // Ascendant axis
            if chart.ascendant != nil {
                var axis = Path()
                axis.move(to: point(ascRef, rInner))
                axis.addLine(to: point(ascRef + 180, rInner))
                context.stroke(axis, with: .color(ringColor.opacity(0.45)),
                               style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                context.draw(
                    Text("ASC")
                        .font(.system(size: rOuter * 0.055, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.primary.opacity(0.6)),
                    at: point(ascRef, rInner + (rOuter - rInner) * 1.35)
                )
            }

            // Aspect chords
            for aspect in chart.aspects {
                guard let pa = chart.positions.first(where: { $0.planet == aspect.a }),
                      let pb = chart.positions.first(where: { $0.planet == aspect.b }) else { continue }
                var chord = Path()
                chord.move(to: point(pa.longitude, rAspect))
                chord.addLine(to: point(pb.longitude, rAspect))
                let strength = 0.15 + 0.35 * (1 - aspect.orb / 8)
                let color: Color = aspect.kind.isHarmonious
                    ? Color(red: 0.37, green: 0.78, blue: 0.6)
                    : .primary
                context.stroke(chord, with: .color(color.opacity(strength)), lineWidth: 1)
            }

            // Planets
            for position in chart.positions {
                let dot = point(position.longitude, rAspect)
                context.fill(Path(ellipseIn: CGRect(x: dot.x - 2.5, y: dot.y - 2.5, width: 5, height: 5)),
                             with: .color(Color.primary.opacity(0.5)))
                context.draw(
                    Text(position.planet.glyph)
                        .font(.system(size: rOuter * 0.095))
                        .foregroundStyle(Color.primary.opacity(0.85)),
                    at: point(position.longitude, rPlanet)
                )
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Birth chart wheel")
        .accessibilityValue(wheelDescription)
    }

    private var wheelDescription: String {
        var parts = chart.positions.map(\.summary)
        if let rising = chart.risingSign {
            parts.insert("\(rising.name) rising", at: 0)
        }
        return parts.joined(separator: ", ")
    }
}
