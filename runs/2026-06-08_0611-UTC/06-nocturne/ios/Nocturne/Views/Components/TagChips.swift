import SwiftUI

private let allTags = ["Caffeine", "Late screen", "Exercise", "Alcohol", "Nap", "Stress"]

/// Multi-select tag chip grid for the log form.
struct TagChips: View {
    @Binding var selected: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(allTags, id: \.self) { tag in
                let isOn = selected.contains(tag)
                Button {
                    Haptics.selection()
                    if isOn {
                        selected.removeAll { $0 == tag }
                    } else {
                        selected.append(tag)
                    }
                } label: {
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isOn ? .white : Brand.text2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            isOn ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(isOn ? Color.clear : Brand.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tag)
                .accessibilityAddTraits(isOn ? .isSelected : [])
                .accessibilityHint(isOn ? "Double tap to remove" : "Double tap to add")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Read-only display of tags as compact chips.
struct TagChipsDisplay: View {
    let tags: [String]

    var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Brand.text3)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Brand.hairline, lineWidth: 0.5))
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tags: \(tags.joined(separator: ", "))")
        }
    }
}

/// Simple flow/wrapping layout.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var maxWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowH + spacing
                x = 0
                rowH = 0
            }
            rowH = max(rowH, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x - spacing)
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
    }
}
