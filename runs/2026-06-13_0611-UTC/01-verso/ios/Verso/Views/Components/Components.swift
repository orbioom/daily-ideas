import SwiftUI

/// Wrapping flow layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct TagChip: View {
    let text: String
    var selected: Bool = false
    var body: some View {
        Text("#\(text)")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(selected ? Color.white : Theme.accent)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(
                Capsule().fill(selected ? Theme.accent : Theme.accentSoft)
            )
    }
}

struct ColorDot: View {
    let index: Int
    var size: CGFloat = 12
    var body: some View {
        Circle()
            .fill(Theme.tagColor(index))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: index == 0 ? 1 : 0))
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.serifTitle(22))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.inkFaint)
    }
}
