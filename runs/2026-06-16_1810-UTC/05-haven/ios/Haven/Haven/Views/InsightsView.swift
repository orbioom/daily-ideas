import SwiftUI
import SwiftData
import Charts

/// Supportive insights framed as progress, not judgment. Swift Charts visualise
/// episodes per week, intensity drop, triggers, time-of-day and what helps.
struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: [SortDescriptor(\PanicEpisode.startedAt, order: .reverse)])
    private var episodes: [PanicEpisode]

    @AppStorage(PrefKey.isPro) private var isPro = false
    @State private var showPaywall = false

    private var stats: StatsEngine { StatsEngine(episodes: episodes) }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenBackground()
                if !stats.hasData {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            heroCard
                            quickStatsRow
                            weeklyChart
                            if isPro {
                                intensityDropCard
                                triggersChart
                                timeOfDayChart
                                whatHelpedCard
                            } else {
                                proTeaser
                            }
                            encouragement
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        EmptyStateView(
            icon: "chart.bar",
            title: "Your insights will grow here",
            message: "Once you've logged a moment or two, you'll see gentle patterns — when things tend to be hard, and what helps most."
        )
    }

    // MARK: Hero

    private var heroCard: some View {
        HavenCard {
            VStack(spacing: 10) {
                Text(heroNumber)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(HavenTheme.calmGreen)
                Text(heroLabel)
                    .font(.subheadline)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(heroNumber) \(heroLabel)")
        }
    }

    private var heroNumber: String {
        if let days = stats.daysSinceLast { return "\(days)" }
        return "—"
    }

    private var heroLabel: String {
        guard let days = stats.daysSinceLast else { return "days since your last hard moment" }
        return days == 1 ? "day since your last hard moment" : "days since your last hard moment"
    }

    // MARK: Quick stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(stats.currentStreak)", label: "day calm streak", icon: "leaf")
            statTile(value: "\(stats.countThisMonth())", label: "this month", icon: "calendar")
            statTile(value: dropText, label: "avg. relief", icon: "arrow.down.heart")
        }
    }

    private var dropText: String {
        guard let drop = stats.averageIntensityDrop else { return "—" }
        return String(format: "%.1f", drop)
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(HavenTheme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(HavenTheme.primaryText(scheme))
            Text(label)
                .font(.caption2)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.vertical, 12)
        .background(HavenTheme.card(scheme))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerMedium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: Weekly chart

    private var weeklyChart: some View {
        let data = stats.episodesPerWeek(weeks: 8)
        return chartCard(title: "Hard moments per week", subtitle: "Last 8 weeks") {
            Chart(data) { bucket in
                BarMark(
                    x: .value("Week", bucket.label),
                    y: .value("Count", bucket.count)
                )
                .foregroundStyle(HavenTheme.accent.gradient)
                .cornerRadius(6)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of hard moments per week over the last eight weeks")
        }
    }

    // MARK: Intensity drop (Pro)

    private var intensityDropCard: some View {
        let before = stats.averageIntensityBefore ?? 0
        let drop = stats.averageIntensityDrop ?? 0
        let after = max(0, before - drop)
        return chartCard(title: "Average relief", subtitle: "How much intensity tends to ease") {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    intensityPill(title: "Before", value: before, color: HavenTheme.softRose)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                        .accessibilityHidden(true)
                    intensityPill(title: "After", value: after, color: HavenTheme.calmGreen)
                }
                Text("On average, intensity eases by \(String(format: "%.1f", drop)) points. You are getting through these.")
                    .font(.caption)
                    .foregroundStyle(HavenTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Average intensity before \(String(format: "%.1f", before)), eases to \(String(format: "%.1f", after))")
        }
    }

    private func intensityPill(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.title.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(HavenTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerSmall, style: .continuous))
    }

    // MARK: Triggers (Pro)

    private var triggersChart: some View {
        let data = stats.topTriggers(limit: 6)
        return chartCard(title: "Most common triggers", subtitle: "What tends to come up") {
            if data.isEmpty {
                placeholderRow("No triggers recorded yet.")
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Trigger", item.name)
                    )
                    .foregroundStyle(HavenTheme.accent.gradient)
                    .cornerRadius(6)
                }
                .frame(height: CGFloat(data.count) * 38 + 20)
                .accessibilityLabel("Most common triggers, ranked by frequency")
            }
        }
    }

    // MARK: Time of day (Pro)

    private var timeOfDayChart: some View {
        let data = stats.timeOfDayDistribution()
        return chartCard(title: "Time of day", subtitle: "When moments tend to arrive") {
            Chart(data) { item in
                BarMark(
                    x: .value("Part", item.part.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(HavenTheme.blush.gradient)
                .cornerRadius(6)
            }
            .frame(height: 170)
            .accessibilityLabel("Distribution of hard moments across night, morning, afternoon, and evening")
        }
    }

    // MARK: What helped (Pro)

    private var whatHelpedCard: some View {
        let data = stats.whatHelped(limit: 6)
        return chartCard(title: "What helps you most", subtitle: "Counted from your entries") {
            if data.isEmpty {
                placeholderRow("Mark what helped when you log a moment, and it'll show here.")
            } else {
                VStack(spacing: 8) {
                    ForEach(data) { item in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(HavenTheme.calmGreen)
                                .accessibilityHidden(true)
                            Text(item.name)
                                .font(.subheadline)
                                .foregroundStyle(HavenTheme.primaryText(scheme))
                            Spacer()
                            Text("\(item.count)×")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(HavenTheme.secondaryText(scheme))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.name), helped \(item.count) times")
                    }
                }
            }
        }
    }

    // MARK: Pro teaser

    private var proTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(HavenTheme.accent)
                            .accessibilityHidden(true)
                        Text("See your full picture")
                            .font(.headline)
                            .foregroundStyle(HavenTheme.primaryText(scheme))
                        Spacer()
                        ProChip()
                    }
                    Text("Haven Plus unlocks average relief, your top triggers, time-of-day patterns, and what helps you most — all private, all on your device.")
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Haven Plus")
    }

    // MARK: Encouragement

    private var encouragement: some View {
        Text("These numbers aren't a scorecard. They're proof that you keep showing up for yourself.")
            .font(.footnote)
            .foregroundStyle(HavenTheme.secondaryText(scheme))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.top, 4)
    }

    // MARK: Building blocks

    private func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(HavenTheme.primaryText(scheme))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(HavenTheme.secondaryText(scheme))
                }
                content()
            }
        }
    }

    private func placeholderRow(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(HavenTheme.secondaryText(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
