import SwiftUI

/// Big answer cards for multiple-choice mode.
struct MultipleChoiceGrid: View {
    let choices: [Int]
    let isEnabled: Bool
    /// The answer the child selected (during feedback), or nil while asking.
    let selectedAnswer: Int?
    let correctAnswer: Int
    let onPick: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(choices, id: \.self) { choice in
                Button {
                    onPick(choice)
                } label: {
                    Text("\(choice)")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(foreground(for: choice))
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background(background(for: choice))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                            .stroke(stroke(for: choice), lineWidth: 2))
                }
                .buttonStyle(PressableStyle())
                .disabled(!isEnabled)
                .accessibilityLabel("\(choice)")
                .accessibilityHint(isEnabled ? "Tap to choose this answer" : "")
            }
        }
    }

    private var showingFeedback: Bool { selectedAnswer != nil }

    private func isCorrect(_ choice: Int) -> Bool { choice == correctAnswer }
    private func isSelected(_ choice: Int) -> Bool { choice == selectedAnswer }

    private func background(for choice: Int) -> Color {
        guard showingFeedback else { return Theme.surface }
        if isCorrect(choice) { return Theme.good.opacity(0.16) }
        if isSelected(choice) { return Theme.bad.opacity(0.16) }
        return Theme.surface
    }

    private func stroke(for choice: Int) -> Color {
        guard showingFeedback else { return Theme.hairline }
        if isCorrect(choice) { return Theme.good }
        if isSelected(choice) { return Theme.bad }
        return Theme.hairline
    }

    private func foreground(for choice: Int) -> Color {
        guard showingFeedback else { return Theme.ink }
        if isCorrect(choice) { return Theme.good }
        if isSelected(choice) { return Theme.bad }
        return Theme.ink.opacity(0.5)
    }
}
