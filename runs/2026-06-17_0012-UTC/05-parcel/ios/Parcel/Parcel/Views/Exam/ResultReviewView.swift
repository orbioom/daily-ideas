import SwiftUI

/// Shown after a session is graded: score, pass/fail, and a per-question review
/// with explanations and the option to redo missed questions.
struct ResultReviewView: View {
    let session: ExamSession
    var onClose: () -> Void
    var onRedoMissed: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var missedCount: Int {
        session.items.filter { $0.isAnswered && !$0.isCorrect }.count
    }
    private var unansweredCount: Int {
        session.items.filter { !$0.isAnswered }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                scoreCard
                breakdownRow
                if session.mode != .mock || missedCount > 0 || unansweredCount > 0 {
                    reviewList
                }
                actions
            }
            .padding(16)
        }
        .background(Theme.background(scheme).ignoresSafeArea())
    }

    private var scoreCard: some View {
        VStack(spacing: 12) {
            ReadinessRing(progress: Double(session.scorePercent) / 100.0,
                          size: 160, lineWidth: 16,
                          label: session.mode.isTimed ? (session.passed ? "Passed" : "Keep going") : "Score")
            Text("\(session.correctCount) of \(session.count) correct")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary(scheme))
            if session.mode.isTimed {
                Label(session.passed ? "You passed the \(session.passPercent)% threshold"
                                     : "Below the \(session.passPercent)% pass mark",
                      systemImage: session.passed ? "checkmark.seal.fill" : "arrow.up.forward")
                    .font(.subheadline)
                    .foregroundStyle(session.passed ? Theme.success(scheme) : Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .cardSurface()
    }

    private var breakdownRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(session.correctCount)", caption: "correct",
                     systemImage: "checkmark.circle", tint: Theme.success(scheme))
            StatTile(value: "\(missedCount)", caption: "missed",
                     systemImage: "xmark.circle", tint: Theme.danger(scheme))
            StatTile(value: timeString(session.elapsedSeconds), caption: "time",
                     systemImage: "clock", tint: Theme.accent)
        }
    }

    private var reviewList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Review", subtitle: "Tap to expand each question")
            ForEach(Array(session.items.enumerated()), id: \.element.id) { idx, item in
                ReviewRow(number: idx + 1, item: item)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if missedCount > 0 {
                Button { onRedoMissed() } label: {
                    Label("Redo missed (\(missedCount))", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Button { onClose() } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 4)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// One expandable review row.
private struct ReviewRow: View {
    let number: Int
    let item: SessionItem
    @Environment(\.colorScheme) private var scheme
    @State private var expanded = false

    private var statusColor: Color {
        if !item.isAnswered { return Theme.textSecondary(scheme) }
        return item.isCorrect ? Theme.success(scheme) : Theme.danger(scheme)
    }
    private var statusSymbol: String {
        if !item.isAnswered { return "minus.circle" }
        return item.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    Image(systemName: statusSymbol)
                        .foregroundStyle(statusColor)
                        .accessibilityHidden(true)
                    Text("\(number). \(item.question.prompt)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary(scheme))
                        .lineLimit(expanded ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary(scheme))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(item.displayedOptions.enumerated()), id: \.offset) { idx, text in
                        HStack(spacing: 8) {
                            Image(systemName: rowSymbol(idx))
                                .foregroundStyle(rowColor(idx))
                                .font(.caption)
                            Text(text)
                                .font(.caption)
                                .foregroundStyle(idx == item.correctPresentationIndex
                                                 ? Theme.textPrimary(scheme) : Theme.textSecondary(scheme))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Divider()
                    Text(item.question.explanation)
                        .font(.caption)
                        .foregroundStyle(Theme.textPrimary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
            }
        }
        .cardSurface(secondary: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question \(number), \(item.isAnswered ? (item.isCorrect ? "correct" : "incorrect") : "unanswered")")
    }

    private func rowSymbol(_ idx: Int) -> String {
        if idx == item.correctPresentationIndex { return "checkmark.circle.fill" }
        if item.selected == idx { return "xmark.circle.fill" }
        return "circle"
    }
    private func rowColor(_ idx: Int) -> Color {
        if idx == item.correctPresentationIndex { return Theme.success(scheme) }
        if item.selected == idx { return Theme.danger(scheme) }
        return Theme.textSecondary(scheme)
    }
}
