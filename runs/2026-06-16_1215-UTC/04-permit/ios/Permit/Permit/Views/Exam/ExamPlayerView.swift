import SwiftUI
import SwiftData

/// Full-screen mock exam: no feedback until submission, a Date-based timer,
/// progress bar, and the ability to flag questions.
struct ExamPlayerView: View {
    let session: ExamSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @State private var index = 0
    @State private var answers: [Int: Int] = [:]
    @State private var flagged: Set<Int> = []
    @State private var startTime = Date()
    @State private var now = Date()
    @State private var showSubmitConfirm = false
    @State private var grade: ExamGrade?
    @State private var savedResult: ExamResult?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var current: Question? {
        session.questions.indices.contains(index) ? session.questions[index] : nil
    }
    private var elapsed: Int { max(0, Int(now.timeIntervalSince(startTime))) }
    private var answeredAll: Bool { answers.count >= session.questions.count }

    var body: some View {
        Group {
            if let grade, let result = savedResult {
                ExamResultView(session: session, grade: grade, result: result, onClose: { dismiss() })
            } else {
                examBody
            }
        }
        .onReceive(timer) { t in now = t }
    }

    private var examBody: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                if let q = current {
                    VStack(alignment: .leading, spacing: 16) {
                        if q.isSignQuestion, let name = q.relatedSign, let sign = SignLibrary.sign(named: name) {
                            HStack { Spacer(); SignView(sign: sign, size: 110); Spacer() }.padding(.top, 4)
                        }
                        Text(q.text)
                            .font(Theme.rounded(21, .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        VStack(spacing: 10) {
                            ForEach(Array(q.options.enumerated()), id: \.offset) { i, opt in
                                OptionCard(index: i, text: opt,
                                           state: answers[q.id] == i ? .selected : .idle,
                                           enabled: true) {
                                    select(i, for: q)
                                }
                            }
                        }
                    }
                    .padding(16)
                } else {
                    EmptyStateView(systemImage: "tray", title: "No questions", message: "This exam is empty.",
                                   actionTitle: "Close", action: { dismiss() })
                }
            }
            bottomBar
        }
        .background(Theme.bg.ignoresSafeArea())
        .confirmationDialog("Submit exam?", isPresented: $showSubmitConfirm, titleVisibility: .visible) {
            Button("Submit now") { submit() }
            Button("Keep going", role: .cancel) {}
        } message: {
            let unanswered = session.questions.count - answers.count
            Text(unanswered > 0 ? "You have \(unanswered) unanswered question\(unanswered == 1 ? "" : "s"). They'll be marked incorrect." : "You've answered every question.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                exitConfirmThenClose()
            } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Exit exam")

            VStack(spacing: 4) {
                Text("Question \(index + 1) of \(session.questions.count)")
                    .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.ink)
                ProgressBarLine(fraction: Double(index + 1) / Double(max(1, session.questions.count)))
            }

            if settings.showTimer {
                Label(timeText, systemImage: "clock")
                    .font(Theme.rounded(13, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityLabel("Time elapsed \(elapsed / 60) minutes \(elapsed % 60) seconds")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .bottom)
    }

    private var timeText: String {
        String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    guard let q = current else { return }
                    toggleFlag(q)
                } label: {
                    Label(isCurrentFlagged ? "Flagged" : "Flag",
                          systemImage: isCurrentFlagged ? "flag.fill" : "flag")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(isCurrentFlagged ? Theme.warn : Theme.inkSoft)
                }
                .accessibilityHint("Marks this question for review")
                Spacer()
                Text("\(answers.count)/\(session.questions.count) answered")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            }
            HStack(spacing: 10) {
                Button {
                    if index > 0 { index -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 50, height: 48)
                        .foregroundStyle(index > 0 ? Theme.accent : Theme.inkSoft)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.rMedium))
                        .overlay(RoundedRectangle(cornerRadius: Theme.rMedium).strokeBorder(Theme.hairline))
                }
                .disabled(index == 0)
                .accessibilityLabel("Previous question")

                if index + 1 < session.questions.count {
                    PrimaryButton(title: "Next", systemImage: "chevron.right") {
                        index += 1
                    }
                } else {
                    PrimaryButton(title: "Submit Exam", systemImage: "paperplane.fill") {
                        showSubmitConfirm = true
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(Rectangle().fill(Theme.hairline).frame(height: 1), alignment: .top)
    }

    private var isCurrentFlagged: Bool {
        guard let q = current else { return false }
        return flagged.contains(q.id)
    }

    // MARK: Actions

    private func select(_ i: Int, for q: Question) {
        answers[q.id] = i
        Haptics.selection(settings.hapticsEnabled)
    }

    private func toggleFlag(_ q: Question) {
        if flagged.contains(q.id) { flagged.remove(q.id) } else { flagged.insert(q.id) }
        Haptics.tap(settings.hapticsEnabled)
    }

    private func exitConfirmThenClose() {
        // Simple, safe exit: dismissing discards the in-progress exam.
        dismiss()
    }

    private func submit() {
        let result = ExamEngine.grade(session: session, answers: answers)
        // Persist per-question stats and flags from this exam.
        for q in session.questions {
            let correct = answers[q.id] == q.correctIndex
            StatStore.record(questionID: q.id, correct: correct, in: context)
            if flagged.contains(q.id) {
                let stat = StatStore.stat(for: q.id, in: context)
                stat.isFlagged = true
            }
        }
        let saved = ExamResult(
            modeRaw: session.mode.rawValue,
            categoryRaw: session.category?.rawValue,
            total: result.total,
            correct: result.correct,
            passed: result.passed,
            durationSec: elapsed,
            missedIDs: result.missedIDs
        )
        StatStore.saveResult(saved, in: context)
        if result.passed { Haptics.success(settings.hapticsEnabled) } else { Haptics.warning(settings.hapticsEnabled) }
        grade = result
        savedResult = saved
    }
}
