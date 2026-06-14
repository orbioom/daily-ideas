import SwiftUI

/// The prompt card. Renders either a large flag glyph or a text prompt, plus the
/// secondary instruction line.
struct QuestionCard: View {
    let question: QuizQuestion

    var body: some View {
        GlassCard(padding: 24) {
            VStack(spacing: 14) {
                if question.promptIsFlag {
                    Text(question.promptPrimary)
                        .font(.system(size: 92))
                        .accessibilityLabel("Flag")
                } else {
                    Text(question.promptPrimary)
                        .font(Theme.rounded(30, .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let secondary = question.promptSecondary {
                    Text(secondary)
                        .font(Theme.rounded(16, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityPrompt)
    }

    private var accessibilityPrompt: String {
        let lead = question.promptIsFlag ? "Flag question" : question.promptPrimary
        return [lead, question.promptSecondary].compactMap { $0 }.joined(separator: ", ")
    }
}

/// A single tappable answer choice with correct/wrong/dimmed feedback styling.
struct ChoiceButton: View {
    enum State { case idle, correct, wrong, dimmed }

    let choice: QuizQuestion.Choice
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let flag = choice.flag {
                    Text(flag)
                        .font(.system(size: 28))
                        .accessibilityHidden(true)
                }
                Text(choice.label)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .foregroundStyle(state == .correct ? Theme.good : Theme.bad)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: 1.5)
            )
            .opacity(state == .dimmed ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.label)
        .accessibilityValue(accessibilityValue)
    }

    private var foreground: Color {
        switch state {
        case .correct: return Theme.good
        case .wrong: return Theme.bad
        default: return Theme.ink
        }
    }
    private var background: Color {
        switch state {
        case .correct: return Theme.good.opacity(0.12)
        case .wrong: return Theme.bad.opacity(0.12)
        default: return Theme.surface
        }
    }
    private var border: Color {
        switch state {
        case .correct: return Theme.good
        case .wrong: return Theme.bad
        default: return Theme.hairline
        }
    }
    private var trailingIcon: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        default: return nil
        }
    }
    private var accessibilityValue: String {
        switch state {
        case .correct: return "Correct answer"
        case .wrong: return "Your answer, incorrect"
        default: return ""
        }
    }
}
