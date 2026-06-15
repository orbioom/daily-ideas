import SwiftUI

/// A compact legend mapping dot colors to meaning + each chapter's swatch.
struct LegendView: View {
    let model: GridModel

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Legend")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)

                FlowRow(spacing: 14, lineSpacing: 8) {
                    legendItem(Theme.accent, "This week")
                    legendItem(Theme.dotPast, "Lived")
                    legendItem(Theme.dotFuture, "Ahead")
                }

                if !model.spans.isEmpty {
                    Divider().background(Theme.hairline)
                    FlowRow(spacing: 14, lineSpacing: 8) {
                        ForEach(model.spans) { span in
                            legendItem(span.color, span.title)
                        }
                    }
                }
            }
        }
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 11, height: 11)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A simple wrapping flow layout (iOS 16+ `Layout`).
struct FlowRow: Layout {
    var spacing: CGFloat = 12
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
