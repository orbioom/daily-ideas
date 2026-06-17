import SwiftUI

/// Draws a glyph's stroke polylines as a static outline inside its frame.
/// Used for lesson grid thumbnails. Normalized 0...1 points are scaled to size.
struct GlyphPreview: View {
    let glyph: Glyph
    var lineWidth: CGFloat = 5
    var color: Color = Theme.inkSoft

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = lineWidth + 2
            let w = max(1, size.width - inset * 2)
            let h = max(1, size.height - inset * 2)
            for stroke in glyph.strokes {
                guard stroke.points.count > 1 else { continue }
                var path = Path()
                let pts = stroke.points.map { CGPoint(x: inset + $0.x * w, y: inset + $0.y * h) }
                path.move(to: pts[0])
                for pt in pts.dropFirst() { path.addLine(to: pt) }
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}
