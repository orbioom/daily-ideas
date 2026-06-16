import SwiftUI
import SwiftData

/// Practice player with INSTANT feedback: pick an option, see correct/incorrect
/// highlight plus an explanation card, then advance to the next question.
struct PracticePlayerView: View {
    let session: ExamSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var index = 0
    @State private var selected: Int?
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var startTime = Date()
    @State private var missedIDs: [Int] = []
    @State private var finished = false

    private var current: Question? {
        session.questions.indices.contains(index) ? session.questions[index] : nil
    }
    private var isAnswered: Bool { selected != nil }
    /// In review mode, explanations are a Pro feature. In normal practice they follow
    /// the instant-explanation preference (always available, free included).
    private var explanationsAllowed: Bool {
        if session.mode == .review { return pro.isPro }
        return settings.instantExplanations
    }

    var body: some View {
        NavigationStack {
            Group {
                if finished {
                    PracticeSummaryView(
                        total: session.questions.count,
                        correct: correctCount,
                        mode: session.mode,
                        onDone: { dismiss() }
                    )
                } else if let q = current {
                    questionView(q)
                } else {
                    EmptyStateView(
                        systemImage: "tray",
                        title: "No questions",
                        message: "This set is empty. Try another practice mode.",
                        actionTitle: "Close",
                        action: { dismiss() }
                    )
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var title: String {
        if let cat = session.category { return cat.title }
        switch session.mode {
        case .review: return "Review"
        default: return "Practice"
        }
    }

    private func questionView(_ q: Question) -> some View {
        VStack(spacing: 0) {
            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(index + 1) of \(session.questions.count)")
                        .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(correctCount) correct")
                        .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.good)
                }
                ProgressBarLine(fraction: Double(index) / Double(max(1, session.questions.count)))
            }
            .padding(.horizontal, 16).padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if q.isSignQuestion, let name = q.relatedSign, let sign = SignLibrary.sign(named: name) {
                        HStack { Spacer(); SignView(sign: sign, size: 110); Spacer() }
                            .padding(.top, 8)
                    }
                    Text(q.text)
                        .font(Theme.rounded(21, .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        ForEach(Array(q.options.enumerated()), id: \.offset) { i, opt in
                            OptionCard(index: i, text: opt, state: state(for: i, in: q), enabled: !isAnswered) {
                                choose(i, in: q)
                            }
                        }
                    }

                    if isAnswered {
                        feedbackCard(q)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(16)
            }

            if isAnswered {
                PrimaryButton(title: index + 1 < session.questions.count ? "Next question" : "Finish",
                              systemImage: "arrow.right") {
                    advance(q)
                }
                .padding(.horizontal, 16).padding(.bottom, 12)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isAnswered)
    }

    private func feedbackCard(_ q: Question) -> some View {
        let correct = selected == q.correctIndex
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                Label(correct ? "Correct" : "Not quite",
                      systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(correct ? Theme.good : Theme.bad)
                if explanationsAllowed {
                    Text(q.explanation)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                } else {
                    HStack(spacing: 8) {
                        ProBadge()
                        Text("Unlock Pro to see explanations everywhere.")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func state(for i: Int, in q: Question) -> OptionState {
        guard let selected else { return .idle }
        if i == q.correctIndex { return .missedCorrect }
        if i == selected { return .wrong }
        return .idle
    }

    private func choose(_ i: Int, in q: Question) {
        guard selected == nil else { return }
        selected = i
        let correct = i == q.correctIndex
        if correct {
            correctCount += 1
            Haptics.success(settings.hapticsEnabled)
        } else {
            missedIDs.append(q.id)
            Haptics.error(settings.hapticsEnabled)
        }
        StatStore.record(questionID: q.id, correct: correct, in: context)
    }

    private func advance(_ q: Question) {
        answeredCount += 1
        if index + 1 < session.questions.count {
            index += 1
            selected = nil
        } else {
            saveResultIfMeaningful()
            withAnimation(reduceMotion ? nil : .easeInOut) { finished = true }
        }
    }

    private func saveResultIfMeaningful() {
        // Record category practice / review sessions so Progress reflects activity.
        let duration = Int(Date().timeIntervalSince(startTime))
        let result = ExamResult(
            modeRaw: session.mode.rawValue,
            categoryRaw: session.category?.rawValue,
            total: session.questions.count,
            correct: correctCount,
            passed: correctCount >= session.requiredCorrect,
            durationSec: max(0, duration),
            missedIDs: missedIDs
        )
        StatStore.saveResult(result, in: context)
    }
}

/// Thin progress line used by players.
struct ProgressBarLine: View {
    let fraction: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule().fill(Theme.accent)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
