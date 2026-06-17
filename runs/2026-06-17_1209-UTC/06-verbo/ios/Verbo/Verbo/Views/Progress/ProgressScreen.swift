import SwiftUI
import SwiftData
import Charts

/// Progress tab: Swift Charts analytics computed asynchronously with a loading state.
struct ProgressScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.isPro) private var isPro = false
    @AppStorage(Prefs.frenchEnabled) private var frenchEnabled = false

    @Query private var allStats: [ItemStat]
    @Query private var allSessions: [DrillSession]

    @State private var language: Language = .spanish
    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    private var availableLanguages: [Language] {
        Language.allCases.filter { $0 == .spanish || (frenchEnabled && isPro) }
    }

    /// Signature that changes when underlying data or language changes.
    private var dataSignature: String {
        let attempts = allStats.reduce(0) { $0 + $1.attempts }
        return "\(language.rawValue)-\(allStats.count)-\(attempts)-\(allSessions.count)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Progress")
            .toolbar {
                if availableLanguages.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            ForEach(availableLanguages) { lang in
                                Button { language = lang } label: {
                                    if language == lang {
                                        Label("\(lang.flag) \(lang.displayName)", systemImage: "checkmark")
                                    } else {
                                        Text("\(lang.flag) \(lang.displayName)")
                                    }
                                }
                            }
                        } label: {
                            Text(language.flag)
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .task(id: dataSignature) { await recompute() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large).tint(Theme.accent)
                Text("Crunching your progress…")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing progress")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    summaryGrid(result)
                    accuracyChart(result)
                    masteryByTenseChart(result)
                    if isPro {
                        masteryByGroupChart(result)
                        weakVerbsCard(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.line.uptrend.xyaxis",
                           title: "No progress yet",
                           message: "Finish a practice session and your accuracy, mastery, and streak will appear here.")
        }
    }

    // MARK: Summary

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Streak", "\(r.streak) day\(r.streak == 1 ? "" : "s")", "flame.fill")
            statCard("Accuracy", "\(Int((r.overallAccuracy * 100).rounded()))%", "percent")
            statCard("Mastered", "\(r.masteredCount)", "checkmark.seal.fill")
            statCard("Attempts", "\(r.totalAttempts)", "number")
        }
    }

    private func statCard(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(24, .bold).monospacedDigit())
                .foregroundStyle(Theme.ink)
            Text(title)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Charts

    private func accuracyChart(_ r: StatsResult) -> some View {
        chartCard(title: "Accuracy over time", symbol: "chart.line.uptrend.xyaxis") {
            if r.accuracyOverTime.isEmpty {
                emptyChartNote("Finish a few sessions to chart your accuracy.")
            } else {
                Chart(r.accuracyOverTime) { point in
                    LineMark(x: .value("Date", point.date),
                             y: .value("Accuracy", point.accuracy))
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", point.date),
                              y: .value("Accuracy", point.accuracy))
                    .foregroundStyle(Theme.accent)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 200)
                .accessibilityLabel("Line chart of accuracy per session over time")
            }
        }
    }

    private func masteryByTenseChart(_ r: StatsResult) -> some View {
        chartCard(title: "Mastery by tense", symbol: "clock.arrow.circlepath") {
            if r.masteryByTense.isEmpty {
                emptyChartNote("Practice a tense to build mastery here.")
            } else {
                Chart(r.masteryByTense) { item in
                    BarMark(x: .value("Mastery", item.mastery),
                            y: .value("Tense", item.label))
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(Int((item.mastery * 100).rounded()))%")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXScale(domain: 0...1)
                .chartXAxis(.hidden)
                .frame(height: CGFloat(r.masteryByTense.count) * 38 + 10)
                .accessibilityLabel("Bar chart of average mastery by tense")
            }
        }
    }

    private func masteryByGroupChart(_ r: StatsResult) -> some View {
        chartCard(title: "Mastery by verb group", symbol: "square.grid.2x2") {
            if r.masteryByGroup.isEmpty {
                emptyChartNote("No group data yet.")
            } else {
                Chart(r.masteryByGroup) { item in
                    BarMark(x: .value("Group", item.label),
                            y: .value("Mastery", item.mastery))
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(5)
                }
                .chartYScale(domain: 0...1)
                .frame(height: 180)
                .accessibilityLabel("Bar chart of mastery by verb group")
            }
        }
    }

    private func weakVerbsCard(_ r: StatsResult) -> some View {
        chartCard(title: "Target these next", symbol: "scope") {
            if r.weakVerbs.isEmpty {
                emptyChartNote("Nothing weak right now — great work!")
            } else {
                VStack(spacing: 10) {
                    ForEach(r.weakVerbs) { w in
                        VStack(spacing: 5) {
                            HStack {
                                Text(w.infinitive)
                                    .font(Theme.rounded(15, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("· \(w.tense.displayName)")
                                    .font(Theme.rounded(13))
                                    .foregroundStyle(Theme.inkSoft)
                                Spacer()
                                Text("\(Int((w.mastery * 100).rounded()))%")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(Theme.bad)
                            }
                            MasteryBar(mastery: w.mastery, height: 6)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock full analytics")
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Verb-group mastery and your weak-spot target list are part of Verbo Pro.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Verbo Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private func chartCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    // MARK: Async compute

    @MainActor
    private func recompute() async {
        isLoading = true
        // Brief delay so the loading state is perceptible on fast devices.
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(stats: allStats, sessions: allSessions, language: language)
        isLoading = false
    }
}
