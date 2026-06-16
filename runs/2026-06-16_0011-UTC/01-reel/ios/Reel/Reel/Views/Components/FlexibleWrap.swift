import SwiftUI

/// A simple wrapping layout that flows items left-to-right and wraps to new lines.
/// Built on iOS 16+ `Layout` so it works on iOS 17.
struct FlexibleWrap<Item: Hashable, Content: View>: View {
    let items: [Item]
    var spacing: CGFloat = 6
    let content: (Item) -> Content

    var body: some View {
        WrapLayout(spacing: spacing) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

/// A wrapping layout container.
struct WrapLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let addedWidth = (rows[rows.count - 1].isEmpty ? 0 : spacing) + size.width
            if currentRowWidth + addedWidth > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([size])
                currentRowWidth = size.width
            } else {
                rows[rows.count - 1].append(size)
                currentRowWidth += addedWidth
            }
        }

        let totalHeight = rows.reduce(CGFloat(0)) { partial, row in
            let rowHeight = row.map { $0.height }.max() ?? 0
            return partial + rowHeight + (partial > 0 ? spacing : 0)
        }
        let totalWidth = proposal.width ?? rows.map { row in
            row.reduce(0) { $0 + $1.width } + CGFloat(max(0, row.count - 1)) * spacing
        }.max() ?? 0
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
