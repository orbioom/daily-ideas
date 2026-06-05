import SwiftUI

// MARK: - Glass surface

/// A Liquid Glass panel using `.ultraThinMaterial` with a hairline luminous edge.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Brand.cardShadow, radius: 14, x: 0, y: 8)
    }
}

// MARK: - Ink primary action

/// The single focal ink action per screen: ink gradient, white label, 12pt radius.
struct InkButton: View {
    var title: String
    var systemImage: String?
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .foregroundStyle(.white)
            .background(Brand.inkGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Rating

/// Read-only star rating with optional half precision via average.
struct RatingDisplay: View {
    var value: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: symbol(for: i))
                    .font(.system(size: size))
                    .foregroundStyle(Brand.text2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue(String(format: "%.1f of 5", value))
    }

    private func symbol(for i: Int) -> String {
        let d = Double(i)
        if value >= d { return "star.fill" }
        if value >= d - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

/// Interactive 1...5 star input.
struct RatingInput: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    rating = i
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundStyle(i <= rating ? Brand.magic : Brand.text3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(i) star\(i == 1 ? "" : "s")")
                .accessibilityAddTraits(i == rating ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rating, \(rating) of 5")
    }
}

// MARK: - Category badge

struct CategoryBadge: View {
    var category: TastingCategory

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: category.symbol).font(.system(size: 11, weight: .semibold))
            Text(category.title).font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(category.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(category.tint.opacity(0.14), in: Capsule())
        .accessibilityElement()
        .accessibilityLabel("Category, \(category.title)")
    }
}

// MARK: - Flavor tag chip + picker

struct FlavorChip: View {
    var label: String
    var selected: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(selected ? .white : Brand.text2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                selected
                    ? AnyShapeStyle(Brand.inkGradient)
                    : AnyShapeStyle(Brand.glassStroke.opacity(0.25)),
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: selected ? 0 : 1))
    }
}

/// A wrapping picker over a category's flavor lexicon with multi-select.
struct FlavorTagPicker: View {
    var lexicon: [String]
    @Binding var selected: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(lexicon, id: \.self) { tag in
                Button {
                    toggle(tag)
                } label: {
                    FlavorChip(label: tag, selected: selected.contains(tag))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected.contains(tag) ? [.isSelected] : [])
                .accessibilityLabel(tag)
            }
        }
    }

    private func toggle(_ tag: String) {
        if let idx = selected.firstIndex(of: tag) {
            selected.remove(at: idx)
        } else {
            selected.append(tag)
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Brand.text3)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).fontWeight(.semibold)
                }
                .padding(.top, 4)
                .tint(Brand.text)
            }
        }
        .frame(maxWidth: 320)
        .padding(28)
    }
}

// MARK: - Bottle row

struct BottleRow: View {
    var bottle: Bottle

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: UInt32(truncatingIfNeeded: bottle.colorHex)))
                .frame(width: 8, height: 46)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(bottle.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                if !bottle.producer.isEmpty || !bottle.origin.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    CategoryBadge(category: bottle.category)
                    if let avg = bottle.averageRating {
                        RatingDisplay(value: avg)
                    }
                }
            }
            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(bottle.tastingCount)")
                    .font(Brand.mono(17, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text(bottle.tastingCount == 1 ? "tasting" : "tastings")
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitle: String {
        [bottle.producer, bottle.origin].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var accessibilityLabel: String {
        var parts = [bottle.name, bottle.category.title]
        if let avg = bottle.averageRating {
            parts.append(String(format: "rated %.1f of 5", avg))
        }
        parts.append("\(bottle.tastingCount) tasting\(bottle.tastingCount == 1 ? "" : "s")")
        return parts.joined(separator: ", ")
    }
}

// MARK: - Flow layout (wrapping chips)

/// A simple wrapping layout for chips; respects available width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth - spacing)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth - spacing)
        return CGSize(width: min(totalWidth, maxWidth), height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
