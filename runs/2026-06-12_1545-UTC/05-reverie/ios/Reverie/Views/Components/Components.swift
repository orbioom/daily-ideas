import SwiftUI

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 46))
                .foregroundStyle(Theme.accent.opacity(0.9)).accessibilityHidden(true)
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent).tint(Theme.accent).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity).padding(28)
    }
}

struct LucidityBadge: View {
    let lucidity: Lucidity
    var body: some View {
        Label(lucidity.label, systemImage: lucidity.symbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background((lucidity == .lucid ? Theme.lucid : Theme.accent).opacity(0.16), in: Capsule())
            .foregroundStyle(lucidity == .lucid ? Theme.lucid : Theme.accent)
    }
}

struct VividnessDots: View {
    let level: Int   // 1...5
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= level ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(i <= level ? Theme.star : Theme.track)
            }
        }
        .accessibilityLabel("Vividness \(level) of 5")
    }
}

struct SignChip: View {
    let sign: DreamSign
    var body: some View {
        Label(sign.name, systemImage: sign.category.symbol)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Theme.track, in: Capsule())
            .foregroundStyle(Theme.textPrimary)
    }
}

struct MiniStat: View {
    var value: String
    var label: String
    var symbol: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint).accessibilityHidden(true)
            Text(value).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .reverieCard()
        .accessibilityElement(children: .combine).accessibilityLabel("\(label): \(value)")
    }
}

/// A simple flow layout for wrapping sign chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var x: CGFloat = 0, totalHeight: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([]); totalHeight += rowHeight + spacing; x = 0; rowHeight = 0
            }
            rows[rows.count - 1].append(sub)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
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
