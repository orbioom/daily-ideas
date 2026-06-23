import SwiftUI

/// A list row showing a phrase: target text, source meaning, pronunciation,
/// a speak button, a favorite toggle, and a maturity dot.
struct PhraseRow: View {
    let phrase: Phrase
    let localeIdentifier: String
    var showPronunciation: Bool
    var speechRate: Double
    var hapticsEnabled: Bool
    var onToggleFavorite: () -> Void

    @ObservedObject private var speech = SpeechManager.shared

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            maturityDot
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.target)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(phrase.source)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if showPronunciation {
                    Text(phrase.pronunciation)
                        .font(.caption.italic())
                        .foregroundStyle(Theme.brand)
                }
            }

            Spacer(minLength: 4)

            VStack(spacing: Theme.Spacing.md) {
                Button(action: speak) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.body)
                        .foregroundStyle(Theme.brand)
                        .frame(width: 36, height: 36)
                        .background(Theme.brand.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play pronunciation")
                .accessibilityHint("Speaks the phrase aloud")

                Button(action: toggleFavorite) {
                    Image(systemName: phrase.isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundStyle(phrase.isFavorite ? Theme.brand : Theme.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(phrase.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .contain)
    }

    private var maturityDot: some View {
        Circle()
            .fill(maturityColor)
            .frame(width: 9, height: 9)
            .accessibilityHidden(true)
    }

    private var maturityColor: Color {
        guard let state = phrase.reviewState, state.totalReviews > 0 else { return Theme.textSecondary.opacity(0.4) }
        switch state.maturity {
        case .new: return Theme.textSecondary.opacity(0.4)
        case .learning: return Theme.warn
        case .mastered: return Theme.success
        }
    }

    private func speak() {
        Haptics.selection(enabled: hapticsEnabled)
        speech.speak(phrase.target, localeIdentifier: localeIdentifier, rate: speechRate)
    }

    private func toggleFavorite() {
        Haptics.tap(enabled: hapticsEnabled)
        onToggleFavorite()
    }
}
