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
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
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
        .frame(maxWidth: 340)
        .padding(28)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section header

struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(Brand.text3)
            .tracking(0.8)
    }
}

// MARK: - Expiry badge

/// Conveys expiry status with an icon + text label tinted by status — never color
/// alone, so it remains legible for color-vision differences and in high contrast.
struct ExpiryBadge: View {
    var bucket: ExpiryLogic.Bucket
    var daysUntil: Int?
    /// When true, shows the relative phrase; otherwise the short bucket title.
    var showPhrase: Bool = false

    private var tint: Color {
        switch bucket {
        case .expired: return Brand.expired
        case .soon:    return Brand.amber
        case .fresh:   return Brand.fresh
        case .none:    return Brand.text3
        }
    }

    private var label: String {
        showPhrase ? ExpiryLogic.relativePhrase(forDaysUntil: daysUntil) : bucket.title
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: bucket.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(bucket.title). \(ExpiryLogic.relativePhrase(forDaysUntil: daysUntil)).")
    }
}

// MARK: - Low-stock badge

struct LowStockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Low")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Brand.amber)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Brand.amber.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.amber.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Low stock")
    }
}

// MARK: - Category chip

struct CategoryChip: View {
    var name: String
    var colorHue: Int
    var symbol: String
    var selected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(selected ? .white : Brand.text2)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            selected
                ? AnyShapeStyle(Brand.categoryColor(colorHue))
                : AnyShapeStyle(Brand.glassStroke.opacity(0.25)),
            in: Capsule()
        )
        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: selected ? 0 : 1))
    }
}

// MARK: - Location glyph

/// A small rounded tile holding a location's SF Symbol.
struct LocationGlyph: View {
    var symbol: String
    var size: CGFloat = 34

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(Brand.glassStroke.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(Brand.text2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Toast feedback

/// A restrained bottom confirmation toast.
struct ToastView: View {
    var message: String
    var icon: String = "checkmark.circle.fill"
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
            Text(message).font(.subheadline.weight(.medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Brand.inkGradient, in: Capsule())
        .shadow(color: Brand.cardShadow, radius: 10, y: 4)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityAddTraits(.isStaticText)
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

#Preview("Components") {
    ZStack {
        Brand.pageBackground
        VStack(spacing: 16) {
            ExpiryBadge(bucket: .soon, daysUntil: 2, showPhrase: true)
            ExpiryBadge(bucket: .expired, daysUntil: -1)
            LowStockBadge()
            CategoryChip(name: "Dairy", colorHue: 1, symbol: "drop.fill", selected: true)
            InkButton(title: "Add Item", systemImage: "plus") {}
        }
        .padding()
    }
}
