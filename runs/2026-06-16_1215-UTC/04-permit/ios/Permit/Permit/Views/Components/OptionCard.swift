import SwiftUI

/// Visual state of an answer option.
enum OptionState {
    case idle          // not yet answered / not selected
    case selected      // selected, no feedback shown yet (exam mode)
    case correct       // revealed correct
    case wrong         // revealed wrong (the user's pick)
    case missedCorrect // the right answer, highlighted after a wrong pick
}

/// A single tappable answer option card with full VoiceOver support.
struct OptionCard: View {
    let index: Int
    let text: String
    let state: OptionState
    var enabled: Bool = true
    let action: () -> Void

    private var background: Color {
        switch state {
        case .idle: return Theme.surface
        case .selected: return Theme.accent.opacity(0.12)
        case .correct, .missedCorrect: return Theme.good.opacity(0.16)
        case .wrong: return Theme.bad.opacity(0.16)
        }
    }

    private var border: Color {
        switch state {
        case .idle: return Theme.hairline
        case .selected: return Theme.accent
        case .correct, .missedCorrect: return Theme.good
        case .wrong: return Theme.bad
        }
    }

    private var trailingIcon: String? {
        switch state {
        case .correct, .missedCorrect: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        default: return nil
        }
    }

    private var iconColor: Color {
        switch state {
        case .wrong: return Theme.bad
        default: return Theme.good
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(Question.letter(index))
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(state == .idle ? Theme.accent : border)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle().fill((state == .idle ? Theme.accent : border).opacity(0.15))
                    )
                    .accessibilityHidden(true)
                Text(text)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .foregroundStyle(iconColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                    .strokeBorder(border, lineWidth: state == .idle ? 1 : 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Option \(Question.letter(index)): \(text)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(state == .selected || state == .correct ? .isSelected : [])
    }

    private var accessibilityValue: String {
        switch state {
        case .idle: return ""
        case .selected: return "Selected"
        case .correct: return "Correct answer"
        case .missedCorrect: return "This was the correct answer"
        case .wrong: return "Incorrect"
        }
    }
}
