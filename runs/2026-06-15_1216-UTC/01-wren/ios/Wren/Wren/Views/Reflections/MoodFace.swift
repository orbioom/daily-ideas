import SwiftUI

/// A calm, drawn mood face (1–5). Not childish — soft, minimal expressions.
struct MoodFace: View {
    var mood: Int          // 1...5
    var size: CGFloat = 44
    var selected: Bool = false

    var body: some View {
        Canvas { ctx, canvasSize in
            draw(ctx: &ctx, size: canvasSize)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(ctx: inout GraphicsContext, size: CGSize) {
        let m = min(5, max(1, mood))
        let w = size.width
        let h = size.height
        let face = Path(ellipseIn: CGRect(x: w * 0.06, y: h * 0.06, width: w * 0.88, height: h * 0.88))
        ctx.fill(face, with: .color(MoodFace.color(m).opacity(selected ? 0.9 : 0.22)))
        ctx.stroke(face, with: .color(MoodFace.color(m)), lineWidth: max(1.5, w * 0.04))

        let eyeColor = selected ? Color.white : Theme.ink
        let eyeY = h * 0.40
        let eyeR = w * 0.05
        for ex in [w * 0.36, w * 0.64] {
            ctx.fill(Path(ellipseIn: CGRect(x: ex - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)),
                     with: .color(eyeColor))
        }

        // Mouth curvature by mood: 1 = down, 3 = flat, 5 = up.
        var mouth = Path()
        let mx0 = w * 0.34, mx1 = w * 0.66, my = h * 0.66
        let curve = CGFloat(m - 3) * h * 0.10  // -0.2h ... +0.2h
        mouth.move(to: CGPoint(x: mx0, y: my))
        mouth.addQuadCurve(to: CGPoint(x: mx1, y: my),
                           control: CGPoint(x: w * 0.5, y: my + curve))
        ctx.stroke(mouth, with: .color(eyeColor), style: StrokeStyle(lineWidth: max(1.5, w * 0.045), lineCap: .round))
    }

    static func label(_ mood: Int) -> String {
        switch min(5, max(1, mood)) {
        case 1: return "Heavy"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        default: return "Bright"
        }
    }

    static func color(_ mood: Int) -> Color {
        switch min(5, max(1, mood)) {
        case 1: return Theme.bad
        case 2: return Theme.warn
        case 3: return Theme.inkSoft
        case 4: return Theme.accent
        default: return Theme.good
        }
    }
}
