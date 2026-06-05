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

// MARK: - Member avatar + chip

/// A circular initial-based avatar tinted by the member's palette color.
struct MemberAvatar: View {
    var member: Member
    var size: CGFloat = 34

    private var initials: String {
        let parts = member.name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        let result = String(letters).uppercased()
        return result.isEmpty ? "?" : result
    }

    var body: some View {
        Circle()
            .fill(Brand.memberColor(member.colorHue).opacity(0.9))
            .frame(width: size, height: size)
            .overlay(
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            )
            .accessibilityHidden(true)
    }
}

/// A compact member chip: avatar + name.
struct MemberChip: View {
    var member: Member
    var selected: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Brand.memberColor(member.colorHue))
                .frame(width: 14, height: 14)
            Text(member.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(selected ? .white : Brand.text2)
                .lineLimit(1)
        }
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

// MARK: - Balance pill

/// Shows a signed money value tinted by sign: green when owed, warm when owing.
struct BalancePill: View {
    var amount: Decimal
    var symbol: String

    private var tint: Color {
        if amount > 0 { return Brand.live }
        if amount < 0 { return Brand.owe }
        return Brand.text3
    }

    var body: some View {
        Text(Money.signedString(amount, symbol: symbol))
            .font(Brand.mono(15, weight: .semibold))
            .foregroundStyle(tint)
            .monospacedDigit()
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

// MARK: - Toast feedback

/// A restrained bottom confirmation toast.
struct ToastView: View {
    var message: String
    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Brand.inkGradient, in: Capsule())
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
