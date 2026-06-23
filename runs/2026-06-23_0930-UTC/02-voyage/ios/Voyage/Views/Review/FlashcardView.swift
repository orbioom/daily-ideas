import SwiftUI

/// A flip flashcard. Front shows the English meaning; back reveals the target
/// phrase + pronunciation. Honors Reduce Motion (cross-fade instead of 3D flip).
struct FlashcardView: View {
    let phrase: Phrase
    let isRevealed: Bool
    let showPronunciation: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            if reduceMotion {
                // Cross-fade between faces, no rotation.
                if isRevealed { back } else { front }
            } else {
                front
                    .opacity(isRevealed ? 0 : 1)
                    .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                back
                    .opacity(isRevealed ? 1 : 0)
                    .rotation3DEffect(.degrees(isRevealed ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: isRevealed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed
            ? "Answer: \(phrase.target). Meaning: \(phrase.source)."
            : "Prompt: \(phrase.source). Double tap Show answer to reveal.")
    }

    private var front: some View {
        cardBody(
            badge: phrase.category.title,
            badgeSymbol: phrase.category.symbol,
            badgeTint: phrase.category.tint,
            primary: phrase.source,
            secondary: "How do you say this?",
            secondaryItalic: false,
            primaryColor: Theme.textPrimary,
            fill: Theme.card
        )
    }

    private var back: some View {
        cardBody(
            badge: phrase.category.title,
            badgeSymbol: phrase.category.symbol,
            badgeTint: .white,
            primary: phrase.target,
            secondary: showPronunciation ? phrase.pronunciation : phrase.source,
            secondaryItalic: showPronunciation,
            primaryColor: .white,
            fill: nil
        )
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
    }

    @ViewBuilder
    private func cardBody(
        badge: String,
        badgeSymbol: String,
        badgeTint: Color,
        primary: String,
        secondary: String,
        secondaryItalic: Bool,
        primaryColor: Color,
        fill: Color?
    ) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack {
                Label(badge, systemImage: badgeSymbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(badgeTint)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 6)
                    .background(badgeTint.opacity(0.18), in: Capsule())
                Spacer()
            }
            Spacer()
            Text(primary)
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(primaryColor)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
            Text(secondary)
                .font(secondaryItalic ? .body.italic() : .body)
                .multilineTextAlignment(.center)
                .foregroundStyle(primaryColor.opacity(0.85))
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(
            Group {
                if let fill {
                    RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous).fill(fill)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(Theme.textSecondary.opacity(fill == nil ? 0 : 0.12), lineWidth: 1)
        )
    }
}

#Preview {
    FlashcardView(
        phrase: Phrase(source: "Where is the train station?", target: "¿Dónde está la estación de tren?", pronunciation: "DON-deh es-TAH...", category: .directions),
        isRevealed: false,
        showPronunciation: true,
        reduceMotion: false
    )
    .padding()
}
