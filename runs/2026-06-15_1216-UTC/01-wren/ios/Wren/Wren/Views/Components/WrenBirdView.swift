import SwiftUI

/// The Wren companion, drawn entirely with SwiftUI shapes. A soft idle "breathing"
/// bob conveys life; it is disabled when Reduce Motion is on. Decorative for VoiceOver
/// (the surrounding scene provides the spoken description).
struct WrenBirdView: View {
    var mood: CompanionMood
    var accessory: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathe = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            Canvas { ctx, size in
                draw(in: &ctx, size: size)
            }
            .frame(width: s, height: s)
            .scaleEffect(breatheScale, anchor: .bottom)
            .offset(y: breatheOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .accessibilityHidden(true)
    }

    private var breatheScale: CGFloat { reduceMotion ? 1 : (breathe ? 1.015 : 0.985) }
    private var breatheOffset: CGFloat { reduceMotion ? 0 : (breathe ? -3 : 3) }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w / 2

        let bodyColor = Color(hex: 0xB97A4E)      // warm wren brown
        let bellyColor = Color(hex: 0xEFD9B8)      // cream belly
        let wingColor = Color(hex: 0x8C5A38)
        let beakColor = Color(hex: 0xD9A05B)

        // Shadow
        let shadow = Path(ellipseIn: CGRect(x: cx - w * 0.24, y: h * 0.86, width: w * 0.48, height: h * 0.08))
        ctx.fill(shadow, with: .color(.black.opacity(0.12)))

        // Body (egg-shaped)
        let bodyRect = CGRect(x: cx - w * 0.30, y: h * 0.30, width: w * 0.60, height: h * 0.56)
        let body = Path(ellipseIn: bodyRect)
        ctx.fill(body, with: .color(bodyColor))

        // Belly
        let bellyRect = CGRect(x: cx - w * 0.20, y: h * 0.46, width: w * 0.40, height: h * 0.38)
        ctx.fill(Path(ellipseIn: bellyRect), with: .color(bellyColor))

        // Wing
        var wing = Path()
        wing.move(to: CGPoint(x: cx + w * 0.04, y: h * 0.44))
        wing.addQuadCurve(to: CGPoint(x: cx + w * 0.26, y: h * 0.66),
                          control: CGPoint(x: cx + w * 0.30, y: h * 0.46))
        wing.addQuadCurve(to: CGPoint(x: cx + w * 0.06, y: h * 0.70),
                          control: CGPoint(x: cx + w * 0.16, y: h * 0.74))
        wing.closeSubpath()
        ctx.fill(wing, with: .color(wingColor))

        // Cocked tail
        var tail = Path()
        tail.move(to: CGPoint(x: cx - w * 0.26, y: h * 0.56))
        tail.addLine(to: CGPoint(x: cx - w * 0.44, y: h * 0.40))
        tail.addLine(to: CGPoint(x: cx - w * 0.30, y: h * 0.66))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(wingColor))

        // Head
        let headRect = CGRect(x: cx - w * 0.22, y: h * 0.20, width: w * 0.44, height: h * 0.40)
        ctx.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // Beak
        var beak = Path()
        beak.move(to: CGPoint(x: cx + w * 0.20, y: h * 0.38))
        beak.addLine(to: CGPoint(x: cx + w * 0.34, y: h * 0.41))
        beak.addLine(to: CGPoint(x: cx + w * 0.20, y: h * 0.44))
        beak.closeSubpath()
        ctx.fill(beak, with: .color(beakColor))

        // Eye (mood-aware): open vs sleepy
        let eyeCenter = CGPoint(x: cx + w * 0.08, y: h * 0.36)
        if mood == .sleepy || mood == .needsYou {
            // Closed/relaxed eye — a small arc
            var lid = Path()
            lid.move(to: CGPoint(x: eyeCenter.x - w * 0.05, y: eyeCenter.y))
            lid.addQuadCurve(to: CGPoint(x: eyeCenter.x + w * 0.05, y: eyeCenter.y),
                             control: CGPoint(x: eyeCenter.x, y: eyeCenter.y + h * 0.03))
            ctx.stroke(lid, with: .color(.black.opacity(0.7)), lineWidth: max(1.5, w * 0.012))
        } else {
            let eye = Path(ellipseIn: CGRect(x: eyeCenter.x - w * 0.035, y: eyeCenter.y - w * 0.035,
                                             width: w * 0.07, height: w * 0.07))
            ctx.fill(eye, with: .color(.black.opacity(0.85)))
            let glint = Path(ellipseIn: CGRect(x: eyeCenter.x - w * 0.005, y: eyeCenter.y - w * 0.02,
                                               width: w * 0.02, height: w * 0.02))
            ctx.fill(glint, with: .color(.white.opacity(0.9)))
        }

        // Accessory overlays
        drawAccessory(in: &ctx, size: size, cx: cx)
    }

    private func drawAccessory(in ctx: inout GraphicsContext, size: CGSize, cx: CGFloat) {
        guard let accessory else { return }
        let w = size.width
        let h = size.height
        switch accessory {
        case "cap":
            var cap = Path()
            cap.move(to: CGPoint(x: cx - w * 0.20, y: h * 0.24))
            cap.addQuadCurve(to: CGPoint(x: cx + w * 0.18, y: h * 0.24),
                             control: CGPoint(x: cx, y: h * 0.06))
            cap.closeSubpath()
            ctx.fill(cap, with: .color(Color(hex: 0xC2614F)))
            let pom = Path(ellipseIn: CGRect(x: cx - w * 0.05, y: h * 0.06, width: w * 0.10, height: w * 0.10))
            ctx.fill(pom, with: .color(Color(hex: 0xEFD9B8)))
        case "scarf":
            var scarf = Path()
            scarf.addRect(CGRect(x: cx - w * 0.20, y: h * 0.56, width: w * 0.40, height: h * 0.07))
            ctx.fill(scarf, with: .color(Color(hex: 0x6E84A3)))
            ctx.fill(Path(CGRect(x: cx - w * 0.06, y: h * 0.60, width: w * 0.08, height: h * 0.14)),
                     with: .color(Color(hex: 0x6E84A3)))
        default:
            break
        }
    }
}
