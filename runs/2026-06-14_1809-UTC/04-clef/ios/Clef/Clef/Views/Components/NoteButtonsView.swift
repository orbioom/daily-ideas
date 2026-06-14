import SwiftUI

/// Note-name answer pad: a row of C D E F G A B (with a ♯/♭ accidental row when on).
struct NoteButtonsView: View {
    let useSolfege: Bool
    let accidentalsOn: Bool
    let useFlats: Bool
    /// Disabled while feedback is showing.
    let disabled: Bool
    let onAnswer: (String, Accidental) -> Void

    @State private var pendingAccidental: Accidental = .natural

    private let letters = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 12) {
            if accidentalsOn {
                accidentalRow
            }
            letterRow
        }
    }

    private var accidentalRow: some View {
        HStack(spacing: 10) {
            ForEach(Accidental.allCases) { acc in
                Button {
                    pendingAccidental = acc
                } label: {
                    Text(accLabel(acc))
                        .font(Theme.rounded(18, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(pendingAccidental == acc ? Theme.accent : Theme.surfaceAlt)
                        )
                        .foregroundStyle(pendingAccidental == acc ? .white : Theme.ink)
                }
                .accessibilityLabel(acc.spokenName)
                .accessibilityAddTraits(pendingAccidental == acc ? .isSelected : [])
            }
        }
    }

    private func accLabel(_ acc: Accidental) -> String {
        switch acc {
        case .natural: return "♮"
        case .sharp: return "♯"
        case .flat: return "♭"
        }
    }

    private var letterRow: some View {
        let columns = [GridItem(.adaptive(minimum: 64), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(letters, id: \.self) { letter in
                Button {
                    onAnswer(letter, accidentalsOn ? pendingAccidental : .natural)
                    pendingAccidental = .natural
                } label: {
                    Text(Pitch.displayLetter(letter, solfege: useSolfege))
                        .font(Theme.serif(22, .semibold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.surface)
                                .shadow(color: Theme.ink.opacity(0.06), radius: 2, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                        .foregroundStyle(Theme.ink)
                }
                .disabled(disabled)
                .accessibilityLabel(spoken(letter))
            }
        }
    }

    private func spoken(_ letter: String) -> String {
        let acc = accidentalsOn && pendingAccidental != .natural ? " " + pendingAccidental.spokenName : ""
        return "Answer \(letter)\(acc)"
    }
}
