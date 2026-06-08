import SwiftUI

/// Horizontal 1–5 mood selector with labels.
struct MoodPicker: View {
    @Binding var value: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { level in
                    let selected = value == level
                    Button {
                        value = level
                        Haptics.selection()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: Mood.symbol(level))
                                .font(.system(size: selected ? 30 : 24))
                                .foregroundStyle(selected ? .white : Mood.color(level))
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle().fill(selected ? Mood.color(level) : Color.clear)
                                )
                                .overlay(
                                    Circle().strokeBorder(Mood.color(level).opacity(selected ? 0 : 0.5), lineWidth: 1.5)
                                )
                                .scaleEffect(selected && !reduceMotion ? 1.05 : 1)
                                .animation(reduceMotion ? nil : Brand.ease(0.25), value: selected)
                            Text(Mood.label(level))
                                .font(.caption2)
                                .foregroundStyle(selected ? Brand.text : Brand.text3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Mood.label(level))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
}

/// Flowing chip layout for activity tags.
struct WrapChips<T: Hashable, Content: View>: View {
    let items: [T]
    var spacing: CGFloat = 8
    @ViewBuilder var content: (T) -> Content

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { item in content(item) }
        }
    }
}

/// Minimal flow layout (chips wrap to new lines).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([]); x = 0
            }
            rows[rows.count - 1].append(size)
            x += size.width + spacing
        }
        let height = rows.reduce(0) { acc, row in
            acc + (row.map(\.height).max() ?? 0) + spacing
        } - spacing
        return CGSize(width: maxWidth == .infinity ? 0 : maxWidth, height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct ActivityChip: View {
    let symbol: String
    let name: String
    var selected: Bool = false
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.caption)
            Text(name).font(.subheadline)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .foregroundStyle(selected ? .white : Brand.text)
        .background(
            Capsule().fill(selected ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial))
        )
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(selected ? 0 : 0.5), lineWidth: 1))
    }
}

struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
