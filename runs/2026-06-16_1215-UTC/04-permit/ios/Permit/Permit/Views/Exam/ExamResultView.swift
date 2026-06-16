import SwiftUI
import SwiftData

struct ExamResultView: View {
    let session: ExamSession
    let grade: ExamGrade
    let result: ExamResult
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @State private var appeared = false
    @State private var reviewSession: ExamSession?

    private var passThresholdPercent: Int { Int((session.passThreshold * 100).rounded()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    badge
                    scoreCard
                    breakdownCard
                    if !grade.missedIDs.isEmpty {
                        reviewButton
                    }
                    PrimaryButton(title: "Back to Study", systemImage: "house.fill", fill: false) {
                        onClose()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }
                }
            }
            .fullScreenCover(item: $reviewSession) { s in
                PracticePlayerView(session: s)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private var badge: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((grade.passed ? Theme.good : Theme.bad).opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: grade.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(grade.passed ? Theme.good : Theme.bad)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
            .accessibilityHidden(true)

            Text(grade.passed ? "You passed!" : "Not yet")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text(grade.passed
                 ? "Great job — you scored at or above the \(passThresholdPercent)% pass mark."
                 : "You need \(session.requiredCorrect) correct (\(passThresholdPercent)%) to pass. Keep practicing!")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(grade.passed ? "Passed" : "Did not pass")
        .accessibilityValue("Scored \(grade.percent) percent")
    }

    private var scoreCard: some View {
        Card {
            HStack {
                stat("Score", "\(grade.percent)%", grade.passed ? Theme.good : Theme.bad)
                Divider().frame(height: 40)
                stat("Correct", "\(grade.correct)/\(grade.total)", Theme.ink)
                Divider().frame(height: 40)
                stat("Time", result.durationText, Theme.ink)
            }
        }
    }

    private func stat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(color)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var breakdownCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("By topic").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                ForEach(breakdown, id: \.category) { row in
                    HStack {
                        Image(systemName: row.category.symbol)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        Text(row.category.title)
                            .font(Theme.rounded(14)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(row.correct)/\(row.total)")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(row.correct == row.total ? Theme.good : Theme.inkSoft)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.category.title): \(row.correct) of \(row.total) correct")
                }
            }
        }
    }

    private struct BreakdownRow { let category: QuestionCategory; let correct: Int; let total: Int }

    private var breakdown: [BreakdownRow] {
        let missed = Set(grade.missedIDs)
        let grouped = Dictionary(grouping: session.questions, by: { $0.category })
        return QuestionCategory.allCases.compactMap { cat in
            guard let qs = grouped[cat], !qs.isEmpty else { return nil }
            let correct = qs.filter { !missed.contains($0.id) }.count
            return BreakdownRow(category: cat, correct: correct, total: qs.count)
        }
    }

    private var reviewButton: some View {
        VStack(spacing: 6) {
            PrimaryButton(title: "Review \(grade.missedIDs.count) missed", systemImage: "magnifyingglass") {
                if pro.isPro {
                    Haptics.tap(settings.hapticsEnabled)
                    reviewSession = ExamEngine.buildReview(missedIDs: grade.missedIDs, flaggedIDs: [], limit: grade.missedIDs.count)
                } else {
                    // Free users can still review questions; explanations are gated within the player.
                    Haptics.tap(settings.hapticsEnabled)
                    reviewSession = ExamEngine.buildReview(missedIDs: grade.missedIDs, flaggedIDs: [], limit: grade.missedIDs.count)
                }
            }
            if !pro.isPro {
                Text("Explanations in review are a Pro feature.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
