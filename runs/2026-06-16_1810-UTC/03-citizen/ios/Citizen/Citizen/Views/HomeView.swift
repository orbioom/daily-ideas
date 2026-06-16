import SwiftUI
import SwiftData

/// Home tab: readiness ring, quick actions, streak, and a daily civics question.
struct HomeView: View {
    @Query private var stats: [QuestionStat]
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]

    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var showSettings = false
    @State private var examMode: ExamMode?
    @State private var showPaywall = false
    @State private var revealDaily = false

    private var readiness: Double { ProgressEngine.readiness(stats: stats) }
    private var streak: Int { ProgressEngine.streak(stats: stats, results: results) }
    private var coverage: Int { ProgressEngine.coverage(stats: stats) }
    private var daily: CivicsQuestion { DailyQuestion.forToday() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    readinessCard
                    quickActions
                    streakAndCoverage
                    dailyQuestionCard
                    if let last = results.first {
                        lastResultCard(last)
                    }
                }
                .padding()
            }
            .screenBackground(scheme)
            .navigationTitle("Citizen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(item: $examMode) { mode in
                ExamSessionView(mode: mode, category: nil)
            }
        }
    }

    // MARK: - Sections

    private var readinessCard: some View {
        VStack(spacing: 16) {
            ReadinessRing(fraction: readiness, caption: "Ready")
                .padding(.top, 4)
            Text(readinessMessage)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary(scheme))
            Button {
                examMode = .mock
            } label: {
                Label("Start Mock Exam", systemImage: "checkmark.seal")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .cardSurface()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickAction("Quick Quiz", "bolt", isPro: false) { examMode = .quick }
            quickAction("Adaptive", "scope", isPro: !prefs.isPro) {
                if prefs.isPro { examMode = .adaptive } else { showPaywall = true }
            }
        }
    }

    private func quickAction(_ title: String, _ icon: String, isPro: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Spacer()
                    if isPro { ProBadge() }
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .cardSurface(secondary: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPro ? "\(title), Pro feature" : title)
    }

    private var streakAndCoverage: some View {
        HStack(spacing: 12) {
            statTile(value: "\(streak)", unit: "day streak",
                     icon: "flame", tint: Theme.gold)
            statTile(value: "\(coverage)/100", unit: "questions seen",
                     icon: "checklist", tint: Theme.accent)
        }
    }

    private func statTile(value: String, unit: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary(scheme))
                    .monospacedDigit()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Spacer(minLength: 0)
        }
        .cardSurface(secondary: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit)")
    }

    private var dailyQuestionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Question of the Day", systemImage: "sun.max")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .textCase(.uppercase)
                Spacer()
                Text("Q\(daily.number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.textSecondary(scheme))
            }
            Text(daily.prompt)
                .font(Theme.serifTitle(20, weight: .medium))
                .foregroundStyle(Theme.textPrimary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            if revealDaily {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(daily.acceptableAnswers.prefix(daily.varies ? 1 : 4), id: \.self) { ans in
                        Label(ans, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.success(scheme))
                    }
                    if let note = daily.note {
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary(scheme))
                            .padding(.top, 2)
                    }
                }
                .transition(.opacity)
            } else {
                Button("Reveal answer") {
                    revealDaily = true
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardSurface()
        .animation(.easeInOut(duration: 0.2), value: revealDaily)
    }

    private func lastResultCard(_ result: ExamResult) -> some View {
        NavigationLink {
            ResultsHistoryView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: result.passed ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(result.passed ? Theme.success(scheme) : Theme.federalRed)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.passed ? "Last exam: Passed" : "Last exam: Keep going")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary(scheme))
                    Text("\(result.modeLabel) \u{00B7} \(result.score)/\(result.total) \u{00B7} \(result.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .accessibilityHidden(true)
            }
            .cardSurface(secondary: true)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens your exam history")
    }

    private var readinessMessage: String {
        switch readiness {
        case ..<0.2: return "Just getting started. Try a few flashcards to warm up."
        case ..<0.5: return "Building a foundation. Keep studying daily."
        case ..<0.75: return "Solid progress \u{2014} you\u{2019}re getting close."
        default: return "You\u{2019}re looking interview-ready. Keep it sharp!"
        }
    }
}
