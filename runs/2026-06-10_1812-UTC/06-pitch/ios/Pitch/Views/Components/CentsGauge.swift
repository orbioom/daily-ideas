import SwiftUI

/// A semicircular gauge with a needle showing cents offset (-50...+50).
/// Turns green within the in-tune window.
struct CentsGauge: View {
    let cents: Double          // -50...50
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double { min(50, max(-50, cents)) }
    private var inTune: Bool { active && abs(cents) <= 5 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let radius = min(w / 2, h) - 12
            let center = CGPoint(x: w / 2, y: h)

            ZStack {
                // Track arc.
                ArcShape(start: .degrees(180), end: .degrees(360))
                    .stroke(Brand.hairline, style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // In-tune zone marker.
                ArcShape(start: .degrees(265), end: .degrees(275))
                    .stroke(Brand.live.opacity(0.5), style: StrokeStyle(lineWidth: 10, lineCap: .round))

                // Tick labels.
                ForEach([-50, -25, 0, 25, 50], id: \.self) { tick in
                    let angle = Angle.degrees(270 + Double(tick) / 50 * 90)
                    Text(tick == 0 ? "0" : "\(tick > 0 ? "+" : "")\(tick)")
                        .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                        .position(
                            x: center.x + cos(angle.radians) * (radius + 2),
                            y: center.y + sin(angle.radians) * (radius + 2)
                        )
                }

                // Needle.
                let needleAngle = Angle.degrees(270 + clamped / 50 * 90)
                Path { p in
                    p.move(to: center)
                    p.addLine(to: CGPoint(x: center.x + cos(needleAngle.radians) * radius,
                                          y: center.y + sin(needleAngle.radians) * radius))
                }
                .stroke(active ? (inTune ? Brand.live : Brand.text) : Brand.text3,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .animation(reduceMotion ? nil : Brand.ease(0.25), value: clamped)

                Circle().fill(active ? (inTune ? Brand.live : Brand.text) : Brand.text3)
                    .frame(width: 14, height: 14)
                    .position(center)
            }
        }
        .accessibilityHidden(true)
    }
}

/// A stroked arc between two angles.
struct ArcShape: Shape {
    let start: Angle
    let end: Angle
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width / 2, rect.height) - 12
        let center = CGPoint(x: rect.width / 2, y: rect.height)
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}
