import SwiftUI

/// A single flashcard with a 3D flip reveal. Under Reduce Motion it cross-fades instead.
struct FlashcardView: View {
    let card: Card
    let isRevealed: Bool
    let reduceMotion: Bool
    let colorSeed: Int
    /// In MCQ/Type modes we don't show the "tap to flip" hint on the front.
    var showFrontTapHint: Bool = true

    private var rotation: Double { isRevealed ? 180 : 0 }

    var body: some View {
        Group {
            if reduceMotion {
                crossFadeCard
            } else {
                flip3DCard
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? "Answer: \(card.back)" : "Question: \(card.front)")
        .accessibilityHint(isRevealed ? "" : (showFrontTapHint ? "Reveal the answer to continue" : ""))
    }

    // MARK: - 3D flip

    private var flip3DCard: some View {
        ZStack {
            face(isBack: false)
                .opacity(isRevealed ? 0 : 1)
            face(isBack: true)
                // Counter-rotate the back so its text isn't mirrored after the flip.
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isRevealed ? 1 : 0)
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isRevealed)
    }

    // MARK: - Cross-fade (reduce motion)

    private var crossFadeCard: some View {
        ZStack {
            if isRevealed {
                face(isBack: true).transition(.opacity)
            } else {
                face(isBack: false).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
    }

    // MARK: - Faces

    @ViewBuilder
    private func face(isBack: Bool) -> some View {
        VStack(spacing: 14) {
            HStack {
                Label(isBack ? "Answer" : "Question",
                      systemImage: isBack ? "lightbulb.fill" : "questionmark.circle.fill")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(isBack ? Theme.accent : Theme.inkFaint)
                Spacer()
                MaturityChip(maturity: card.maturity)
            }

            Spacer(minLength: 0)

            Text(isBack ? card.back : card.front)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            if isBack {
                if card.hasExample {
                    Text(card.example)
                        .font(Theme.rounded(15))
                        .italic()
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                if card.hasHint {
                    Text(card.hint)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer(minLength: 0)

            if !isBack && showFrontTapHint {
                Text("Tap Show answer")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 240)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(
                    isBack ? AnyShapeStyle(Theme.deckGradient(seed: colorSeed)) : AnyShapeStyle(Theme.hairline),
                    lineWidth: isBack ? 2 : 1
                )
        )
        .shadow(color: Theme.accent.opacity(0.08), radius: 14, y: 6)
    }
}

#Preview {
    VStack(spacing: 20) {
        FlashcardView(card: Card(front: "hola", back: "hello", hint: "greeting", example: "¡Hola! ¿Cómo estás?"),
                      isRevealed: false, reduceMotion: false, colorSeed: 1)
        FlashcardView(card: Card(front: "hola", back: "hello", hint: "greeting", example: "¡Hola! ¿Cómo estás?"),
                      isRevealed: true, reduceMotion: false, colorSeed: 1)
    }
    .padding()
    .background(Theme.bg)
}
