import SwiftUI
import SwiftData

struct StudyHomeView: View {
    @Binding var selectedTab: RootView.Tab
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query private var stats: [QuestionStat]
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]

    @State private var examSession: ExamSession?
    @State private var practiceSession: ExamSession?
    @State private var showPaywall = false
    @State private var limitMessage: String?

    private var readiness: Int { ProgressEngine.readiness(stats: stats) }
    private var streak: Int { ProgressEngine.studyStreak(stats: stats, results: results) }
    private var lastResult: ExamResult? { results.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    readinessCard
                    fullMockButton
                    quickActions
                    if !pro.isPro {
                        ProInlineBanner(message: "Unlock Permit Pro for all topics, unlimited mocks and full explanations.") {
                            showPaywall = true
                        }
                    }
                    lastResultCard
                    disclaimerNote
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Permit")
            .toast($limitMessage)
            .fullScreenCover(item: $examSession) { session in
                ExamPlayerView(session: session)
            }
            .fullScreenCover(item: $practiceSession) { session in
                PracticePlayerView(session: session)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                Text(settings.studyState.isEmpty ? "Ready to study?" : "Studying in \(settings.studyState)")
                    .font(Theme.rounded(22, .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            streakPill
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var streakPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(streak > 0 ? Theme.warn : Theme.inkSoft)
            Text("\(streak)").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.hairline))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Study streak")
        .accessibilityValue("\(streak) \(streak == 1 ? "day" : "days")")
    }

    private var readinessCard: some View {
        Card {
            HStack(spacing: 20) {
                ReadinessRing(percent: readiness, size: 120, caption: "Ready")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exam readiness")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(readinessBlurb)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Text("\(ProgressEngine.masteredCount(stats: stats)) of \(QuestionBank.count) questions mastered")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var readinessBlurb: String {
        switch readiness {
        case 80...: return "You're looking exam-ready. Keep sharp with mock tests."
        case 50..<80: return "Solid progress. Drill your weak areas to push higher."
        case 1..<50: return "Good start. Practice each topic to build mastery."
        default: return "Take a quick practice round to begin tracking your readiness."
        }
    }

    private var fullMockButton: some View {
        VStack(spacing: 6) {
            PrimaryButton(title: "Start Full Mock Exam", systemImage: "checkmark.seal.fill") {
                startFullMock()
            }
            if !pro.isPro {
                Text("\(pro.mocksRemainingToday) of \(ProStore.freeMocksPerDay) free mock\(ProStore.freeMocksPerDay == 1 ? "" : "s") left today")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var quickActions: some View {
        VStack(spacing: 10) {
            ActionTile(title: "Quick Practice", subtitle: "A short 12-question warm-up", systemImage: "bolt.fill", tint: Theme.accent) {
                startQuickPractice()
            }
            ActionTile(title: "Weak Areas", subtitle: "Adaptive set targeting your gaps", systemImage: "target", tint: Theme.warn) {
                startWeakAreas()
            }
            ActionTile(title: "Review Missed", subtitle: "Revisit flagged & missed questions", systemImage: "arrow.uturn.backward.circle.fill", tint: Theme.bad) {
                startReview()
            }
        }
    }

    @ViewBuilder
    private var lastResultCard: some View {
        if let r = lastResult {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Last result").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text(r.date, format: .relative(presentation: .named))
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    }
                    HStack(spacing: 16) {
                        passBadge(r.passed)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(r.scorePercent)% • \(r.correct)/\(r.total)")
                                .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                            Text("\(r.mode.label) • \(r.durationText)")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private func passBadge(_ passed: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(passed ? Theme.good : Theme.bad)
            Text(passed ? "Pass" : "Fail")
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(passed ? Theme.good : Theme.bad)
        }
        .accessibilityElement(children: .combine)
    }

    private var disclaimerNote: some View {
        Text("Questions cover general US rules of the road. Always confirm state-specific limits and laws in your official driver handbook.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    // MARK: Actions

    private func startFullMock() {
        guard pro.canStartMock else {
            Haptics.warning(settings.hapticsEnabled)
            limitMessage = "Daily free mock used — unlock Pro for unlimited"
            showPaywall = true
            return
        }
        pro.registerMockStarted()
        Haptics.tap(settings.hapticsEnabled)
        examSession = ExamEngine.buildFullMock(length: settings.mockLength.rawValue)
    }

    private func startQuickPractice() {
        Haptics.tap(settings.hapticsEnabled)
        practiceSession = ExamEngine.buildQuickMock(length: 12)
    }

    private func startWeakAreas() {
        Haptics.tap(settings.hapticsEnabled)
        var accuracy: [Int: Double] = [:]
        var seen = Set<Int>()
        for s in stats {
            if s.timesSeen > 0 { seen.insert(s.questionID); accuracy[s.questionID] = s.accuracy }
        }
        practiceSession = ExamEngine.buildWeakAreas(accuracyByID: accuracy, seenIDs: seen, count: 15)
    }

    private func startReview() {
        let ids = ProgressEngine.reviewableIDs(stats: stats)
        let session = ExamEngine.buildReview(missedIDs: ids.missed, flaggedIDs: ids.flagged, limit: 20)
        if session.isEmpty {
            limitMessage = "Nothing to review yet — take a practice round"
            return
        }
        Haptics.tap(settings.hapticsEnabled)
        practiceSession = session
    }
}
