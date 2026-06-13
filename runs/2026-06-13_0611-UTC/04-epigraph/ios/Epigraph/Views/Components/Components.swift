import SwiftUI

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(title).font(Theme.serif(22, .bold)).foregroundStyle(Theme.ink)
            Text(message).font(.system(size: 15)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 34)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Capsule().fill(Theme.accent)).foregroundStyle(.white)
                }.padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 50)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

struct ThemeChip: View {
    let text: String
    var selected: Bool = false
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .serif))
            .foregroundStyle(selected ? .white : Theme.accent)
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(Capsule().fill(selected ? Theme.accent : Theme.accentSoft))
    }
}

/// A quotation rendered in Epigraph's letterpress style.
struct QuoteView: View {
    let text: String
    var size: CGFloat = 22
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("“").font(Theme.serif(size * 1.8, .bold)).foregroundStyle(Theme.accent)
                .offset(y: size * 0.35).accessibilityHidden(true)
            Text(text)
                .font(Theme.serif(size))
                .italic()
                .foregroundStyle(Theme.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.serif(24, .bold)).foregroundStyle(Theme.accent)
            Text(label.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.5)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}
