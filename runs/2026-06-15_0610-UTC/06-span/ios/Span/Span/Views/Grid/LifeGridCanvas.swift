import SwiftUI

/// High-performance week-dot grid drawn with a single `Canvas`. Renders 4500+ cells smoothly
/// by drawing primitives directly rather than instantiating thousands of views. A tap is
/// mapped back to a grid index by the same layout math. The grid is decorative for VoiceOver;
/// a meaningful summary label is supplied by the parent screen.
struct LifeGridCanvas: View {
    let model: GridModel
    let dotStyle: DotStyle
    let glowEnabled: Bool
    /// Drives the current-week pulse when glow is enabled (0...1).
    let pulse: Double
    /// Called with the tapped grid index.
    var onSelect: (Int) -> Void
    /// The currently selected index, drawn with a ring.
    var selectedIndex: Int?

    @State private var width: CGFloat = 0

    var body: some View {
        let layout = Layout(width: width, columns: model.columns, rows: model.rows)
        Canvas { ctx, _ in
            draw(in: &ctx, layout: layout)
        }
        .frame(maxWidth: .infinity)
        .frame(height: width > 0 ? layout.totalHeight : 1)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { width = geo.size.width }
                    .onChange(of: geo.size.width) { _, newValue in width = newValue }
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    if let idx = layout.index(at: value.location, total: model.totalWeeks) {
                        onSelect(idx)
                    }
                }
        )
    }

    private func draw(in ctx: inout GraphicsContext, layout: Layout) {
        let size = layout.dotSize
        let spacing = layout.spacing
        let pastColor = Theme.dotPast
        let futureColor = Theme.dotFuture

        for index in 0..<model.totalWeeks {
            let row = index / model.columns
            let col = index % model.columns
            let x = layout.originX + CGFloat(col) * (size + spacing)
            let y = CGFloat(row) * (size + spacing)
            let rect = CGRect(x: x, y: y, width: size, height: size)
            let radius = dotStyle.cornerRadius(for: size)
            let path = Path(roundedRect: rect, cornerRadius: radius)

            let isCurrent = index == model.currentIndex
            let isFuture = index > model.currentIndex

            // Fill color: chapter wins, else past/future tone.
            let fill: Color
            if isCurrent {
                fill = Theme.accent
            } else if let c = model.chapterColor(at: index) {
                fill = isFuture ? c.opacity(0.32) : c
            } else {
                fill = isFuture ? futureColor : pastColor
            }
            ctx.fill(path, with: .color(fill))

            // Current-week glow ring (skipped when Reduce Motion is on via glowEnabled).
            if isCurrent {
                let glowAlpha = glowEnabled ? (0.35 + 0.5 * pulse) : 0.7
                let ringRect = rect.insetBy(dx: -size * 0.55, dy: -size * 0.55)
                let ringPath = Path(roundedRect: ringRect,
                                    cornerRadius: dotStyle.cornerRadius(for: ringRect.width))
                ctx.stroke(ringPath,
                           with: .color(Theme.accent.opacity(glowAlpha)),
                           lineWidth: max(size * 0.18, 1))
            }

            // Milestone marker: a small inner dot.
            if model.hasMilestone(at: index) && !isCurrent {
                let inner = rect.insetBy(dx: size * 0.28, dy: size * 0.28)
                ctx.fill(Path(ellipseIn: inner), with: .color(Theme.surface))
            }

            // Selection ring.
            if let sel = selectedIndex, sel == index {
                let selRect = rect.insetBy(dx: -size * 0.45, dy: -size * 0.45)
                ctx.stroke(Path(roundedRect: selRect,
                                cornerRadius: dotStyle.cornerRadius(for: selRect.width)),
                           with: .color(Theme.ink),
                           lineWidth: max(size * 0.18, 1.2))
            }
        }
    }

    /// Pure layout math, reused for drawing and hit-testing.
    struct Layout {
        let dotSize: CGFloat
        let spacing: CGFloat
        let originX: CGFloat
        let columns: Int
        let rows: Int

        init(width: CGFloat, columns: Int, rows: Int) {
            self.columns = max(columns, 1)
            self.rows = max(rows, 1)
            let cols = CGFloat(max(columns, 1))
            // Spacing scales with available width; clamp dot size to a sane range.
            let raw = (width) / (cols * 1.34)
            let dot = min(max(raw, 3), 14)
            self.dotSize = dot
            self.spacing = max(dot * 0.34, 1)
            let used = cols * dot + (cols - 1) * self.spacing
            self.originX = max((width - used) / 2, 0)
        }

        var totalHeight: CGFloat {
            CGFloat(rows) * dotSize + CGFloat(max(rows - 1, 0)) * spacing
        }

        func index(at point: CGPoint, total: Int) -> Int? {
            let stride = dotSize + spacing
            guard stride > 0 else { return nil }
            let col = Int((point.x - originX + spacing / 2) / stride)
            let row = Int((point.y + spacing / 2) / stride)
            guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
            let idx = row * columns + col
            guard idx >= 0, idx < total else { return nil }
            return idx
        }
    }
}
