import SwiftUI

/// Result-review screen: pass/fail, score, and a per-question breakdown of the
/// user's answer vs. the correct answer plus the explanation/note.
struct ExamResultView: View {
    let model: ExamSessionModel
    let onDone: () -> Void
    let onRetry: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                verdictCard
                breakdownSection
                actions
            }
            .padding()
        }
    }

    private var verdictCard: some View {
        VStack(spacing: 14) {
            Image(systemName: model.didPass ? "checkmark.seal.fill" : "flag.checkered")
                .font(.system(size: 56))
                .foregroundStyle(model.didPass ? Theme.success(scheme) : Theme.federalRed)
                .accessibilityHidden(true)
            Text(model.didPass ? "You passed!" : "Almost there")
                .font(Theme.largeTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text("\(model.score) of \(model.total) correct")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textSecondary(scheme))
            Text(model.didPass
                 ? "That clears the \(model.passThreshold)-correct bar. Keep practicing to stay sharp."
                 : "You need \(model.passThreshold) of \(model.total). Review the misses below and try again.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
            Label("Finished in \(model.elapsedFormatted)", systemImage: "timer")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.didPass ? "Passed" : "Not yet passed"). \(model.score) of \(model.total) correct.")
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Review", subtitle: "Your answer vs. the correct answer")
            ForEach(Array(model.items.enumerated()), id: \.element.id) { idx, item in
                breakdownRow(index: idx, item: item)
            }
        }
    }

    private func breakdownRow(index: Int, item: ExamItem) -> some View {
        let correct = model.isCorrect(itemIndex: index)
        let answer = index < model.answers.count ? model.answers[index] : ExamAnswer()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusIcon(item: item, correct: correct, answer: answer))
                    .foregroundStyle(statusTint(item: item, correct: correct))
                    .accessibilityHidden(true)
                Text(item.question.prompt)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if item.isSelfCheck {
                detailLine("Self-check", answer.knewIt == true ? "You said you knew it" : "You weren\u{2019}t sure", tint: Theme.textSecondary(scheme))
                if let note = item.question.note {
                    detailLine("Note", note, tint: Theme.textSecondary(scheme))
                }
            } else {
                let chosen = chosenText(item: item, answer: answer)
                detailLine("Your answer", chosen, tint: correct ? Theme.success(scheme) : Theme.federalRed)
                if !correct {
                    detailLine("Correct", item.question.primaryAnswer, tint: Theme.success(scheme))
                }
                if let note = item.question.note {
                    detailLine("Note", note, tint: Theme.textSecondary(scheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(secondary: true)
        .accessibilityElement(children: .combine)
    }

    private func detailLine(_ label: String, _ value: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(label):")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textSecondary(scheme))
            Text(value)
                .font(.caption)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button("Try another", action: onRetry)
                .buttonStyle(PrimaryButtonStyle())
            Button("Done", action: onDone)
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Helpers

    private func chosenText(item: ExamItem, answer: ExamAnswer) -> String {
        guard let sel = answer.selectedIndex, sel >= 0, sel < item.choices.count else {
            return "Not answered"
        }
        return item.choices[sel]
    }

    private func statusIcon(item: ExamItem, correct: Bool, answer: ExamAnswer) -> String {
        if item.isSelfCheck {
            return answer.knewIt == true ? "checkmark.circle.fill" : "circle.dashed"
        }
        return correct ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func statusTint(item: ExamItem, correct: Bool) -> Color {
        if item.isSelfCheck { return Theme.accent }
        return correct ? Theme.success(scheme) : Theme.federalRed
    }
}
