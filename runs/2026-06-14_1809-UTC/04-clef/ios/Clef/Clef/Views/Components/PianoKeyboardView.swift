import SwiftUI

/// A one-octave piano keyboard answer pad. Tapping a key answers with that note name.
/// White keys = naturals C–B; black keys = sharps/flats (only active when accidentals on).
struct PianoKeyboardView: View {
    let showLabels: Bool
    let accidentalsOn: Bool
    let useFlats: Bool
    let useSolfege: Bool
    let disabled: Bool
    let onAnswer: (String, Accidental) -> Void

    // White keys (letter) and the black key (sharp letter) that follows each, if any.
    private let whites: [String] = ["C", "D", "E", "F", "G", "A", "B"]
    // Black key after index i (nil if none): C#, D#, -, F#, G#, A#, -
    private let blackAfter: [String?] = ["C", "D", nil, "F", "G", "A", nil]

    var body: some View {
        GeometryReader { geo in
            let count = whites.count
            let whiteWidth = geo.size.width / CGFloat(count)
            let height = geo.size.height
            let blackWidth = whiteWidth * 0.62
            let blackHeight = height * 0.60

            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(Array(whites.enumerated()), id: \.offset) { _, letter in
                        whiteKey(letter, width: whiteWidth, height: height)
                    }
                }
                // Black keys overlaid
                ForEach(Array(blackAfter.enumerated()), id: \.offset) { i, base in
                    if let base, accidentalsOn {
                        let x = whiteWidth * CGFloat(i + 1) - blackWidth / 2
                        blackKey(base: base, width: blackWidth, height: blackHeight)
                            .offset(x: x, y: 0)
                    }
                }
            }
        }
        .frame(height: 150)
    }

    private func whiteKey(_ letter: String, width: CGFloat, height: CGFloat) -> some View {
        Button {
            onAnswer(letter, .natural)
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.dyn(0xFFFFFF, 0xEDE9F5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Theme.staff.opacity(0.5), lineWidth: 1)
                    )
                if showLabels {
                    Text(Pitch.displayLetter(letter, solfege: useSolfege))
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Color.dyn(0x3A3450, 0x3A3450))
                        .padding(.bottom, 8)
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel("Answer \(letter)")
    }

    private func blackKey(base: String, width: CGFloat, height: CGFloat) -> some View {
        // The black key answers as base-sharp or its flat enharmonic per the setting.
        let accidental: Accidental = useFlats ? .flat : .sharp
        // For flats, the answer letter is the note above; compute via Pitch.
        let answerLetter: String
        if useFlats {
            // The flat name of (base sharp) — e.g. C# → Db answers as letter "D".
            answerLetter = flatLetterAbove(base)
        } else {
            answerLetter = base
        }
        return Button {
            onAnswer(answerLetter, accidental)
        } label: {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.dyn(0x231F2E, 0x0C0A12))
                if showLabels {
                    Text(useFlats ? "\(answerLetter)♭" : "\(base)♯")
                        .font(Theme.rounded(10, .semibold))
                        .foregroundStyle(.white)
                        .padding(.bottom, 6)
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel("Answer \(base) \(accidental.spokenName)")
    }

    /// The natural letter directly above `base` in C D E F G A B (wraps B→C).
    private func flatLetterAbove(_ base: String) -> String {
        let order = ["C", "D", "E", "F", "G", "A", "B"]
        guard let idx = order.firstIndex(of: base) else { return base }
        return order[(idx + 1) % order.count]
    }
}
