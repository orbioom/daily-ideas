import SwiftUI

struct MoonCanvasView: View {
    let phaseAngle: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowOpacity: Double = 0.3

    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2 - 4
            let cx = size.width / 2
            let cy = size.height / 2

            // Dark sphere
            ctx.fill(
                Path { p in p.addEllipse(in: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)) },
                with: .color(Color(red: 0.04, green: 0.04, blue: 0.10))
            )

            let isFull  = phaseAngle > 0.483 && phaseAngle < 0.517
            let isNew   = phaseAngle < 0.034 || phaseAngle > 0.966

            if isFull {
                ctx.fill(
                    Path { p in p.addEllipse(in: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)) },
                    with: .color(Color(red: 0.95, green: 0.92, blue: 0.85))
                )
            } else if !isNew {
                let path = litPath(cx: cx, cy: cy, r: r)
                ctx.fill(path, with: .color(Color(red: 0.95, green: 0.92, blue: 0.85)))
            }

            // Edge glow
            ctx.stroke(
                Path { p in p.addEllipse(in: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)) },
                with: .color(Color.white.opacity(isFull ? 0.3 : 0.12)),
                lineWidth: isFull ? 3 : 1
            )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
        .accessibilityLabel("Moon phase illustration")
    }

    private let k = 0.5523

    private func litPath(cx: CGFloat, cy: CGFloat, r: CGFloat) -> Path {
        var path = Path()
        let top    = CGPoint(x: cx, y: cy - r)
        let bottom = CGPoint(x: cx, y: cy + r)

        if phaseAngle < 0.5 {
            let tx = cos(phaseAngle * 2 * .pi) * r
            path.move(to: top)
            path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            let c1 = CGPoint(x: cx + tx * k, y: cy + r * 0.85)
            let c2 = CGPoint(x: cx + tx * k, y: cy - r * 0.85)
            path.addCurve(to: top, control1: c1, control2: c2)
        } else {
            let tx = -cos(phaseAngle * 2 * .pi) * r
            path.move(to: top)
            path.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                        startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
            let c1 = CGPoint(x: cx + tx * k, y: cy + r * 0.85)
            let c2 = CGPoint(x: cx + tx * k, y: cy - r * 0.85)
            path.addCurve(to: top, control1: c1, control2: c2)
        }
        return path
    }
}
