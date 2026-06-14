import SwiftUI

// MARK: - Card surface

/// A standard Lexeme card: paper surface, soft hairline, rounded corners.
struct LexemeCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Tier badge

struct TierBadge: View {
    let tier: WordTier
    var body: some View {
        Text(tier.label)
            .font(Theme.rounded(11, .semibold))
            .tracking(0.4)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
            .accessibilityLabel("\(tier.label) tier")
    }
    private var color: Color {
        switch tier {
        case .everyday: return Theme.inkSoft
        case .sat:      return Theme.teal
        case .gre:      return Theme.gold
        }
    }
}

// MARK: - Part of speech tag

struct POSTag: View {
    let pos: PartOfSpeech
    var body: some View {
        Text(pos.abbrev)
            .font(Theme.serif(13).italic())
            .foregroundStyle(Theme.inkSoft)
            .accessibilityLabel(pos.label)
    }
}

// MARK: - Word chip (synonyms / antonyms / tags)

struct WordChip: View {
    let text: String
    var tint: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(Theme.rounded(13, .medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

/// A wrapping row of chips (lightweight flow layout).
struct ChipFlow: View {
    let items: [String]
    var tint: Color = Theme.accent
    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(items, id: \.self) { item in
                WordChip(text: item, tint: tint)
            }
        }
    }
}

/// Minimal flow layout (iOS 16+ Layout protocol).
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        var rowHeights: [CGFloat] = [0]
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                rows.append([]); rowHeights.append(0); x = 0
            }
            rows[rows.count - 1].append(size)
            rowHeights[rowHeights.count - 1] = max(rowHeights[rowHeights.count - 1], size.height)
            x += size.width + spacing
        }
        let totalHeight = rowHeights.reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth && x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(enabled ? Theme.accent : Theme.inkFaint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent.opacity(0.7))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.serif(22, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(15, .semibold))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Theme.accentSoft, in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading state

struct LoadingView: View {
    var message: String = "Preparing..."
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Theme.accent)
                .controlSize(.large)
            Text(message)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Section header

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.rounded(12, .semibold))
            .tracking(1.2)
            .foregroundStyle(Theme.inkFaint)
    }
}

// MARK: - Pro lock badge

struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill").font(.system(size: 9))
            Text("PRO").font(Theme.rounded(10, .bold)).tracking(0.5)
        }
        .foregroundStyle(Theme.gold)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Theme.gold.opacity(0.15), in: Capsule())
        .accessibilityLabel("Requires Lexeme Pro")
    }
}
