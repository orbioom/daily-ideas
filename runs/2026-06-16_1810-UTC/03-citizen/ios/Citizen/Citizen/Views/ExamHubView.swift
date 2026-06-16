import SwiftUI
import SwiftData

/// Exam tab: pick a mode (and category) and launch a full-screen session.
struct ExamHubView: View {
    @Query private var stats: [QuestionStat]
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]

    @Environment(AppPreferences.self) private var prefs
    @Environment(\.colorScheme) private var scheme

    @State private var launch: ExamLaunch?
    @State private var showPaywall = false
    @State private var pickingCategory = false

    /// Free users get a few mock exams per day; this counts today's mock/quick runs.
    private var todaysGradedCount: Int {
        let cal = Calendar.current
        return results.filter { cal.isDateInToday($0.date) }.count
    }
    private let freeDailyLimit = 3
    private var freeLimitReached: Bool { !prefs.isPro && todaysGradedCount >= freeDailyLimit }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard

                    ForEach(ExamMode.allCases) { mode in
                        modeRow(mode)
                    }

                    if !prefs.isPro {
                        freeLimitNote
                    }
                }
                .padding()
            }
            .screenBackground(scheme)
            .navigationTitle("Exam")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Choose a category", isPresented: $pickingCategory, titleVisibility: .visible) {
                ForEach(CivicsCategory.allCases) { cat in
                    Button(cat.title) { launch = ExamLaunch(mode: .category, category: cat) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(item: $launch) { l in
                ExamSessionView(mode: l.mode, category: l.category)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The Real Test")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary(scheme))
            Text("In the interview, an officer asks up to 10 of the 100 questions. You pass at 6 correct \u{2014} and they stop early once you reach 6.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func modeRow(_ mode: ExamMode) -> some View {
        Button {
            handleTap(mode)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(mode.title)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary(scheme))
                        if mode.requiresPro && !prefs.isPro { ProBadge() }
                    }
                    Text(mode.subtitle)
                        .font(.subheadline)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title). \(mode.subtitle)\(mode.requiresPro && !prefs.isPro ? ". Pro feature" : "")")
    }

    private var freeLimitNote: some View {
        HStack(spacing: 10) {
            Image(systemName: freeLimitReached ? "hourglass" : "checkmark.circle")
                .foregroundStyle(freeLimitReached ? Theme.federalRed : Theme.success(scheme))
                .accessibilityHidden(true)
            Text(freeLimitReached
                 ? "You\u{2019}ve used today\u{2019}s \(freeDailyLimit) free exams. Upgrade for unlimited."
                 : "\(max(0, freeDailyLimit - todaysGradedCount)) of \(freeDailyLimit) free exams left today.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary(scheme))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private func handleTap(_ mode: ExamMode) {
        if mode.requiresPro && !prefs.isPro {
            showPaywall = true
            return
        }
        if !mode.requiresPro && freeLimitReached {
            showPaywall = true
            return
        }
        if mode == .category {
            pickingCategory = true
        } else {
            launch = ExamLaunch(mode: mode, category: nil)
        }
    }
}

/// Identifiable wrapper so we can drive `fullScreenCover(item:)`.
struct ExamLaunch: Identifiable {
    let id = UUID()
    let mode: ExamMode
    let category: CivicsCategory?
}
