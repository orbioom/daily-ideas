import SwiftUI

/// A drawn Moon phase glyph showing the illuminated fraction and waxing/waning side.
/// Decorative — callers should provide an accessibility label on the container.
struct MoonGlyph: View {
    /// Illuminated fraction [0,1].
    let illumination: Double
    /// True if waxing (lit on the right in the northern convention).
    let waxing: Bool
    var size: CGFloat = 48

    var body: some View {
        Canvas { ctx, canvasSize in
            let r = min(canvasSize.width, canvasSize.height) / 2
            guard r > 0.5 else { return }
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let discRect = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
            let full = Path(ellipseIn: discRect)

            // Dark Moon disc + limb.
            ctx.fill(full, with: .color(Color(hex: 0x1A2238)))
            ctx.stroke(full, with: .color(Color(hex: 0x3A4869)), lineWidth: 0.8)

            let frac = min(1, max(0, illumination))
            guard frac > 0.005 else { return }

            let lit = Color(hex: 0xF3EFD8)
            ctx.clip(to: full)

            if frac >= 0.995 {
                ctx.fill(full, with: .color(lit))
                return
            }

            // The lit region is bounded by:
            //  - the outer limb (a semicircle on the lit side), and
            //  - the terminator (a half-ellipse whose half-width = r·(1−2·frac)).
            // For waxing, the lit side is the right; for waning, the left.
            // termHalfWidth > 0 → terminator bulges toward the dark side (crescent, frac<0.5).
            // termHalfWidth < 0 → terminator bulges toward the lit side (gibbous, frac>0.5).
            let termHalfWidth = r * (1 - 2 * frac)
            let sign: CGFloat = waxing ? 1 : -1

            var path = Path()
            let steps = 72
            // Outer limb: from top to bottom along the lit semicircle.
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let y = center.y - r + CGFloat(t) * 2 * r
                let dy = (y - center.y) / r
                let chord = r * CGFloat(sqrt(max(0, 1 - Double(dy * dy))))
                let x = center.x + sign * chord
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            // Terminator: back from bottom to top.
            for i in stride(from: steps, through: 0, by: -1) {
                let t = Double(i) / Double(steps)
                let y = center.y - r + CGFloat(t) * 2 * r
                let dy = (y - center.y) / r
                let chord = r * CGFloat(sqrt(max(0, 1 - Double(dy * dy))))
                let x = center.x + sign * (termHalfWidth / r) * chord
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
            ctx.fill(path, with: .color(lit))
        }
        .frame(width: size, height: size)
    }
}
