import SwiftUI

/// Pure renderer for a coloring page using SwiftUI `Canvas`. Draws each region filled
/// (or unfilled white), then strokes outlines for the line-art look. Optionally draws
/// by-number labels. No interaction here — the interactive layer wraps this.
struct PageCanvasView: View {
    let page: ColoringPage
    /// regionID -> hex color string
    let fills: [Int: String]
    var palette: Palette
    var showOutlines: Bool = true
    var showNumbers: Bool = false
    /// When set, the region whose color was just placed (for a subtle highlight).
    var highlightedRegion: Int? = nil

    var body: some View {
        Canvas { ctx, size in
            let dim = min(size.width, size.height)
            let originX = (size.width - dim) / 2
            let originY = (size.height - dim) / 2
            let square = CGSize(width: dim, height: dim)
            let origin = CGPoint(x: originX, y: originY)

            // Paper background.
            let bgRect = CGRect(x: origin.x, y: origin.y, width: dim, height: dim)
            ctx.fill(Path(roundedRect: bgRect, cornerRadius: dim * 0.03),
                     with: .color(Theme.regionUnfilled))

            for region in page.regions {
                let scaled = Geometry.scaled(region.points, to: square, origin: origin)
                let path = Geometry.path(scaled)
                if path.isEmpty { continue }

                let fillColor: Color
                if let hex = fills[region.id], let c = Color(hexString: hex) {
                    fillColor = c
                } else {
                    fillColor = Theme.regionUnfilled
                }
                ctx.fill(path, with: .color(fillColor))

                if region.id == highlightedRegion {
                    ctx.stroke(path, with: .color(Theme.accent), lineWidth: max(dim * 0.006, 2))
                } else if showOutlines {
                    ctx.stroke(path, with: .color(Theme.regionStroke),
                               lineWidth: max(dim * 0.0028, 0.6))
                }
            }

            if showNumbers {
                for region in page.regions where fills[region.id] == nil {
                    let center = region.centroid
                    let px = origin.x + center.x * dim
                    let py = origin.y + center.y * dim
                    let number = region.suggestedColorIndex + 1
                    let text = Text("\(number)")
                        .font(.system(size: max(dim * 0.018, 7), weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.regionStroke.opacity(0.8))
                    ctx.draw(text, at: CGPoint(x: px, y: py), anchor: .center)
                }
            }
        }
        .drawingGroup() // rasterize for smooth pan/zoom at 100+ regions
    }
}
