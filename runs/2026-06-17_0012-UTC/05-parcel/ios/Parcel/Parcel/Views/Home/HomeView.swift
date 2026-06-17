import SwiftUI
import SwiftData

/// The study dashboard: readiness, mode launchers, streak, and weak-topic nudges.
struct HomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Environment(AppPreferences.self) private var prefs

    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]
    @Query private var stats: [QuestionStat]

    @State private var activeSession: ExamSession?
    @State private var showPaywall = false
    @State private var emptyReviewAlert = false

    private var readiness: Double {
        ProgressEngine.readiness(stats: stats, totalQuestions: QuestionBank.all.count)
    }
    private var streak: Int { ProgressEngine.studyStreak(results: results) }
    private var weakest: [Topic] { ProgressEngine.weakestTopics(stats: stats, limit: 3) }
    private var hasActivity: Bool { stats.contains { $0.seen > 0 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    readinessCard
                    if let last = results.first { lastResultCard(last) }
                    modesSection
                    if hasActivity { weakTopicsSection }
                    footer
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Parcel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !prefs.isPro {
                        Button { showPaywall = true } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(Theme.gold)
                    }
                }
            }
            .fullScreenCover(item: $activeSession) { session in
                ExamSessionView(session: session)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .alert("Nothing to review yet", isPresented: $emptyReviewAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Answer some questions first. Missed and flagged questions will collect here for focused review.")
            }
        }
    }

    // MARK: Readiness

    private var readinessCard: some View {
        VStack(spacing: 14) {
            ReadinessRing(progress: readiness, label: "Ready")
            HStack(spacing: 12) {
                StatTile(value: "\(streak)", caption: streak == 1 ? "day streak" : "day streak",
                         systemImage: "flame.fill", tint: Theme.gold)
                StatTile(value: "\(Int((ProgressEngine.coverage(stats: stats, totalQuestions: QuestionBank.all.count) * 100).rounded()))%",
                         caption: "bank covered", systemImage: "checklist", tint: Theme.accent)
                StatTile(value: "\(ProgressEngine.totalAnswered(stats: stats))",
                         caption: "answered", systemImage: "questionmark.circle", tint: Theme.success(scheme))
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    private func lastResultCard(_ r: ExamResult) -> some View {
        HStack(spacing: 14) {
            Image(systemName: r.passed ? "checkmark.seal.fill" : "arrow.uturn.up")
                .font(.title2)
                .foregroundStyle(r.passed ? Theme.success(scheme) : Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Last: \(r.modeLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                Text("\(r.score)/\(r.total) · \(r.percent)%  ·  \(r.date.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Spacer()
        }
        .cardSurface(secondary: true)
        .accessibilityElement(children: .combine)
    }

    // MARK: Modes

    private var modesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Practice")
            ForEach(ExamMode.allCases) { mode in
                Button { launch(mode) } label: { ModeRow(mode: mode, locked: isLocked(mode)) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func isLocked(_ mode: ExamMode) -> Bool {
        !prefs.isPro && !mode.isFree
    }

    private func launch(_ mode: ExamMode) {
        if isLocked(mode) { showPaywall = true; return }
        if mode == .review {
            let ids = StatStore.reviewPoolIds(in: context)
            if ids.isEmpty { emptyReviewAlert = true; return }
        }
        let session = ExamSession.make(mode: mode, prefs: prefs, context: context)
        if session.isEmpty { emptyReviewAlert = true; return }
        Haptics.light(enabled: prefs.hapticsEnabled)
        activeSession = session
    }

    // MARK: Weak topics

    private var weakTopicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Focus areas", subtitle: "Your lowest-mastery topics right now")
            ForEach(weakest) { topic in
                HStack(spacing: 12) {
                    Image(systemName: topic.systemImage)
                        .foregroundStyle(topic.chipColor)
                        .frame(width: 26)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(topic.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary(scheme))
                        MasteryBar(value: ProgressEngine.topicMastery(topic, stats: stats),
                                   tint: topic.chipColor)
                    }
                    Spacer()
                    Button {
                        let s = ExamSession.make(mode: .topic, prefs: prefs, topic: topic, context: context)
                        if !s.isEmpty { activeSession = s }
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Practice \(topic.title)")
                }
                .cardSurface(secondary: true)
            }
        }
    }

    private var footer: some View {
        Text("National exam content for study only — not legal advice. Check your state's specific licensing requirements.")
            .font(.caption2)
            .foregroundStyle(Theme.textSecondary(scheme))
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}

/// A single mode launcher row.
private struct ModeRow: View {
    let mode: ExamMode
    let locked: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: mode.systemImage)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    if locked { ProBadge() }
                }
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
                .accessibilityHidden(true)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title)\(locked ? ", Pro feature" : "")")
        .accessibilityHint(mode.subtitle)
    }
}
