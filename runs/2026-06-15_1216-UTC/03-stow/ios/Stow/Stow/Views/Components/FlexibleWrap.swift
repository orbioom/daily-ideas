import SwiftUI

/// A wrapping HStack built on the iOS 16+ Layout protocol. Lays children out
/// left-to-right, wrapping to new rows as needed.
struct FlexibleWrap<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    let data: Data
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        WrapLayout(spacing: spacing, rowSpacing: rowSpacing) {
            ForEach(data) { element in
                content(element)
            }
        }
    }
}

struct WrapLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } +
            CGFloat(max(0, rows.count - 1)) * rowSpacing
        let width = rows.map(\.width).max() ?? 0
        rows.removeAll()
        return CGSize(width: min(width, maxWidth.isFinite ? maxWidth : width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxWidth = bounds.width
        var y = bounds.minY
        var index = 0
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        for row in rows {
            var x = bounds.minX
            for _ in row.items {
                guard index < subviews.count else { break }
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
                index += 1
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var items: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        var x: CGFloat = 0
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let needed = (current.items.isEmpty ? 0 : spacing) + size.width
            if x + needed > maxWidth, !current.items.isEmpty {
                rows.append(current)
                current = Row()
                x = 0
            }
            if !current.items.isEmpty { x += spacing }
            current.items.append(i)
            x += size.width
            current.width = x
            current.height = max(current.height, size.height)
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}
