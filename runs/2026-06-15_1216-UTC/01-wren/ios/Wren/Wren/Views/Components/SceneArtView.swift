import SwiftUI

/// Drawn "postcard" art for earned collectibles. Each scene id maps to a calm,
/// shape-based illustration. Decorative for VoiceOver (callers supply a label).
struct SceneArtView: View {
    var scene: String

    var body: some View {
        Canvas { ctx, size in
            draw(in: &ctx, size: size)
        }
        .accessibilityHidden(true)
    }

    private func palette(_ scene: String) -> (sky: Color, mid: Color, fore: Color, accent: Color) {
        switch scene {
        case "meadow":
            return (Color(hex: 0xCFE3C4), Color(hex: 0x9CC089), Color(hex: 0x6F9C5C), Color(hex: 0xE0A050))
        case "harbour":
            return (Color(hex: 0xCBD9E6), Color(hex: 0x88A6C2), Color(hex: 0x4F6A86), Color(hex: 0xE0C060))
        case "highland":
            return (Color(hex: 0xE8C7A8), Color(hex: 0xB98E78), Color(hex: 0x6E5848), Color(hex: 0xE07A5B))
        case "cap", "scarf", "cache":
            return (Color(hex: 0xF0E2CF), Color(hex: 0xD9BE99), Color(hex: 0xB08A5C), Color(hex: 0xE07A5B))
        default:
            return (Color(hex: 0xE6DCC9), Color(hex: 0xCBB88F), Color(hex: 0x9C8458), Color(hex: 0xE07A5B))
        }
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let p = palette(scene)

        // Sky
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(p.sky))

        // Sun / moon
        let orb = Path(ellipseIn: CGRect(x: w * 0.66, y: h * 0.14, width: w * 0.16, height: w * 0.16))
        ctx.fill(orb, with: .color(p.accent.opacity(0.85)))

        // Rolling mid hills
        var hill = Path()
        hill.move(to: CGPoint(x: 0, y: h * 0.66))
        hill.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.60), control: CGPoint(x: w * 0.25, y: h * 0.50))
        hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.64), control: CGPoint(x: w * 0.75, y: h * 0.70))
        hill.addLine(to: CGPoint(x: w, y: h))
        hill.addLine(to: CGPoint(x: 0, y: h))
        hill.closeSubpath()
        ctx.fill(hill, with: .color(p.mid))

        // Foreground hill
        var fore = Path()
        fore.move(to: CGPoint(x: 0, y: h * 0.82))
        fore.addQuadCurve(to: CGPoint(x: w * 0.6, y: h * 0.78), control: CGPoint(x: w * 0.3, y: h * 0.70))
        fore.addQuadCurve(to: CGPoint(x: w, y: h * 0.84), control: CGPoint(x: w * 0.85, y: h * 0.88))
        fore.addLine(to: CGPoint(x: w, y: h))
        fore.addLine(to: CGPoint(x: 0, y: h))
        fore.closeSubpath()
        ctx.fill(fore, with: .color(p.fore))

        // A tiny perched wren silhouette
        let bird = Path(ellipseIn: CGRect(x: w * 0.18, y: h * 0.66, width: w * 0.09, height: w * 0.07))
        ctx.fill(bird, with: .color(p.fore.opacity(0.9)))
        var tail = Path()
        tail.move(to: CGPoint(x: w * 0.18, y: h * 0.69))
        tail.addLine(to: CGPoint(x: w * 0.13, y: h * 0.64))
        tail.addLine(to: CGPoint(x: w * 0.18, y: h * 0.71))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(p.fore.opacity(0.9)))
    }
}
