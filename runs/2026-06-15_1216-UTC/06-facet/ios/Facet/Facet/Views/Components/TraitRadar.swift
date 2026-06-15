import SwiftUI

/// A five-axis radar (pentagon) visualization of the Big Five, drawn with Canvas.
/// Optionally overlays a second profile for compatibility comparisons.
struct TraitRadar: View {
    let primary: ScoredResult
    var secondary: ScoredResult? = nil
    var primaryColor: Color = Theme.accent
    var secondaryColor: Color = Theme.good

    private let traits = Trait.allCases

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.78
            let n = traits.count
            guard n > 0, radius > 0 else { return }

            // Grid rings
            for ring in 1...4 {
                let r = radius * CGFloat(ring) / 4
                var path = Path()
                for i in 0..<n {
                    let p = point(center: center, radius: r, index: i, count: n)
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(Theme.hairline), lineWidth: 1)
            }

            // Axes
            for i in 0..<n {
                var path = Path()
                path.move(to: center)
                path.addLine(to: point(center: center, radius: radius, index: i, count: n))
                context.stroke(path, with: .color(Theme.hairline.opacity(0.7)), lineWidth: 1)
            }

            // Secondary polygon (drawn first, behind)
            if let secondary {
                drawPolygon(context: context, center: center, radius: radius,
                            result: secondary, color: secondaryColor)
            }
            // Primary polygon
            drawPolygon(context: context, center: center, radius: radius,
                        result: primary, color: primaryColor)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trait radar chart")
        .accessibilityValue(accessibilityDescription)
    }

    private func drawPolygon(context: GraphicsContext, center: CGPoint, radius: CGFloat,
                             result: ScoredResult, color: Color) {
        let n = traits.count
        var path = Path()
        for (i, trait) in traits.enumerated() {
            let score = max(0, min(100, result.score(for: trait)))
            let r = radius * CGFloat(score / 100)
            let p = point(center: center, radius: r, index: i, count: n)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color.opacity(0.22)))
        context.stroke(path, with: .color(color), lineWidth: 2)
    }

    private func point(center: CGPoint, radius: CGFloat, index: Int, count: Int) -> CGPoint {
        // Start at top, go clockwise.
        let angle = (-Double.pi / 2) + (2 * Double.pi * Double(index) / Double(count))
        return CGPoint(x: center.x + radius * CGFloat(cos(angle)),
                       y: center.y + radius * CGFloat(sin(angle)))
    }

    private var accessibilityDescription: String {
        let parts = primary.traitScores.map { "\($0.trait.rawValue) \(Int($0.score)) percent" }
        var desc = parts.joined(separator: ", ")
        if let secondary {
            let sParts = secondary.traitScores.map { "\($0.trait.rawValue) \(Int($0.score)) percent" }
            desc += ". Comparison: " + sParts.joined(separator: ", ")
        }
        return desc
    }
}
