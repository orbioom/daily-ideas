import SwiftUI

/// Builds a consistent VoiceOver label for a card, e.g. "The Star, reversed" or "Ace of Cups, upright".
func cardAccessibilityLabel(_ card: TarotCard, reversed: Bool) -> String {
    "\(card.name), \(reversed ? "reversed" : "upright")"
}

/// A small keyword chip.
struct KeywordChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.accentDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Theme.accentSoft)
            )
            .accessibilityLabel("Keyword: \(text)")
    }
}

/// A flowing row of keyword chips.
struct KeywordRow: View {
    let keywords: [String]
    var body: some View {
        FlexWrap(spacing: 8, lineSpacing: 8) {
            ForEach(keywords, id: \.self) { KeywordChip(text: $0) }
        }
    }
}

/// A simple wrapping layout for chips (iOS 17 Layout protocol).
struct FlexWrap: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
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

/// A reusable empty-state panel.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent.opacity(0.85))
            Text(title)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.accent))
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A primary, full-width capsule button.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(disabled ? Theme.accent.opacity(0.4) : Theme.accent)
            )
            .foregroundStyle(.white)
        }
        .disabled(disabled)
    }
}

/// A small "Pro" badge.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.goldSoft))
            .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1))
            .accessibilityLabel("Pro feature")
    }
}

/// The gentle disclaimer shown in onboarding, settings, and the library intro.
struct ReflectionNote: View {
    var body: some View {
        Text("Arcana is for reflection and entertainment. It offers prompts for journaling and self-insight — not medical, legal, or financial advice.")
            .font(.footnote)
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

/// A small mood picker (1...5).
struct MoodPicker: View {
    @Binding var mood: Int?
    private let faces = ["cloud.rain", "cloud", "sun.haze", "sun.max", "sparkles"]
    private let labels = ["Heavy", "Low", "Even", "Bright", "Radiant"]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<faces.count, id: \.self) { i in
                let value = i + 1
                Button {
                    mood = (mood == value) ? nil : value
                } label: {
                    Image(systemName: faces[i])
                        .font(.system(size: 22))
                        .foregroundStyle(mood == value ? .white : Theme.inkSoft)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle().fill(mood == value ? Theme.accent : Theme.surfaceAlt)
                        )
                }
                .accessibilityLabel(labels[i])
                .accessibilityAddTraits(mood == value ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}
