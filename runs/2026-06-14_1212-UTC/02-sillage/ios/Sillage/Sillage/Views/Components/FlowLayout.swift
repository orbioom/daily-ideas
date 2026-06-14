import SwiftUI

/// A simple wrapping layout (iOS 16+ `Layout`) for chips and tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let height = rows.last.map { $0.maxY } ?? 0
        let width = maxWidth.isFinite ? maxWidth : (rows.flatMap { $0.items }.map { $0.x + $0.size.width }.max() ?? 0)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        for row in rows {
            for item in row.items {
                let pt = CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y)
                subviews[item.index].place(at: pt, anchor: .topLeading, proposal: ProposedViewSize(item.size))
            }
        }
    }

    private struct Item { let index: Int; let x: CGFloat; let size: CGSize }
    private struct Row { var y: CGFloat; var items: [Item]; var height: CGFloat; var maxY: CGFloat { y + height } }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowItems: [Item] = []
        var rowHeight: CGFloat = 0

        for (index, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rowItems.isEmpty {
                rows.append(Row(y: y, items: rowItems, height: rowHeight))
                y += rowHeight + spacing
                x = 0
                rowItems = []
                rowHeight = 0
            }
            rowItems.append(Item(index: index, x: x, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        if !rowItems.isEmpty {
            rows.append(Row(y: y, items: rowItems, height: rowHeight))
        }
        return rows
    }
}
