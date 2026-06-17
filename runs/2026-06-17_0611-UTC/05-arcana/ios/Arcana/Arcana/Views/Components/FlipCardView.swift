import SwiftUI

/// A card that reveals its face with a flip animation, or — under Reduce Motion — a calm
/// cross-fade still fallback. Tapping (when not yet revealed) reveals it.
struct FlipCardView: View {
    let card: TarotCard
    var reversed: Bool = false
    @Binding var revealed: Bool
    var deckTheme: DeckTheme = .midnight
    var onReveal: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                // Still fallback: simple cross-fade, no 3D rotation.
                if revealed {
                    CardArtView(card: card, reversed: reversed)
                } else {
                    CardBackView(theme: deckTheme)
                }
            } else {
                // 3D flip: back and face on opposite sides.
                CardBackView(theme: deckTheme)
                    .opacity(revealed ? 0 : 1)
                    .rotation3DEffect(.degrees(revealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                CardArtView(card: card, reversed: reversed)
                    .opacity(revealed ? 1 : 0)
                    .rotation3DEffect(.degrees(revealed ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.55, dampingFraction: 0.8),
                   value: revealed)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !revealed else { return }
            revealed = true
            onReveal?()
        }
        .accessibilityElement()
        .accessibilityAddTraits(revealed ? [] : .isButton)
        .accessibilityLabel(revealed ? cardAccessibilityLabel(card, reversed: reversed) : "Face-down card")
        .accessibilityHint(revealed ? "" : "Double-tap to reveal")
    }
}
