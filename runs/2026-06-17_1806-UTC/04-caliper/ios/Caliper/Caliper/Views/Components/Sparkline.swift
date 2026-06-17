import SwiftUI

/// A tiny, dependency-free trend line for summary cards. Purely decorative;
/// the surrounding card carries the accessible value.
struct Sparkline: View {
    let values: [Double]
    var lineColor: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                if pts.count >= 2 {
                    // Soft fill under the line.
                    Path { p in
                        p.move(to: CGPoint(x: pts[0].x, y: geo.size.height))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.22), lineColor.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    Path { p in
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                } else {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                        p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                    }
                    .stroke(Theme.hairline, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let span = maxV - minV
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { idx, v in
            let x = CGFloat(idx) * stepX
            let normalized = span > 0 ? (v - minV) / span : 0.5
            let y = size.height - CGFloat(normalized) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}
