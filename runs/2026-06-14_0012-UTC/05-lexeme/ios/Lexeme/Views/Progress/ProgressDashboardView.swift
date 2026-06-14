import SwiftUI
import SwiftData
import Charts

/// Stats dashboard: words learned over time, mastery distribution, accuracy,
/// streak, a 7-day due forecast, and achievements. Full charts are Pro; the free
/// tier sees headline numbers and a sample.
struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var progress: [WordProgress]
    @Query(sort: \StudySession.date, order: .reverse) private var sessions: [StudySession]
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    private var learned: Int { LexemeEngine.learnedCount(progress) }
    private var streak: Int { LexemeEngine.streak(sessions) }
    private var accuracy: Double { LexemeEngine.overallAccuracy(sessions) }
    private var distribution: [Int] { LexemeEngine.masteryDistribution(progress) }
    private var forecast: [Int] { LexemeEngine.dueForecast(progress, days: 7) }
    private var overTime: [(date: Date, count: Int)] { LexemeEngine.learnedOverTime(progress, days: 30) }
    private var achievements: [Achievement] { AchievementEngine.all(progress: progress, sessions: sessions) }

    private var hasAnyData: Bool { !progress.isEmpty || !sessions.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if !hasAnyData {
                    EmptyStateView(systemImage: "chart.line.uptrend.xyaxis",
                                   title: "No progress yet",
                                   message: "Study a few words and your stats — streak, mastery, accuracy and forecasts — will grow here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statTiles
                            cumulativeChart
                            masteryDonut
                            forecastChart
                            achievementsSection
                            if !isPro { proNote }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Progress")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Stat tiles

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(learned)", label: "Learned", icon: "checkmark.seal.fill", tint: Theme.good)
            StatTile(value: "\(streak)", label: "Day streak", icon: "flame.fill", tint: Theme.gold)
            StatTile(value: "\(Int((accuracy * 100).rounded()))%", label: "Accuracy", icon: "target", tint: Theme.accent)
        }
    }

    // MARK: - Cumulative learned (line)

    private var cumulativeChart: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Words learned (last 30 days)")
                if isPro {
                    if cumulative.allSatisfy({ $0.total == 0 }) {
                        miniEmpty("Mark words as learned to chart your growth.")
                    } else {
                        Chart(cumulative) { point in
                            AreaMark(x: .value("Day", point.date), y: .value("Total", point.total))
                                .foregroundStyle(Theme.accent.opacity(0.18))
                            LineMark(x: .value("Day", point.date), y: .value("Total", point.total))
                                .foregroundStyle(Theme.accent)
                                .interpolationMethod(.monotone)
                        }
                        .chartYAxis { AxisMarks(position: .leading) }
                        .frame(height: 160)
                    }
                } else {
                    proLockedChart(height: 160)
                }
            }
        }
    }

    /// Cumulative running total of learned words across the window.
    private var cumulative: [LearnedPoint] {
        var running = 0
        return overTime.map { point in
            running += point.count
            return LearnedPoint(date: point.date, total: running)
        }
    }

    // MARK: - Mastery donut

    private var masteryDonut: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Mastery distribution")
                let total = distribution.reduce(0, +)
                if total == 0 {
                    miniEmpty("No words in your schedule yet.")
                } else {
                    HStack(spacing: 18) {
                        Chart(masterySlices) { slice in
                            SectorMark(angle: .value("Count", slice.count),
                                       innerRadius: .ratio(0.62),
                                       angularInset: 1.5)
                                .foregroundStyle(slice.color)
                                .cornerRadius(3)
                        }
                        .frame(width: 130, height: 130)

                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(masterySlices) { slice in
                                if slice.count > 0 {
                                    HStack(spacing: 7) {
                                        Circle().fill(slice.color).frame(width: 9, height: 9)
                                        Text(slice.name).font(Theme.rounded(13)).foregroundStyle(Theme.ink)
                                        Spacer()
                                        Text("\(slice.count)").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var masterySlices: [MasterySlice] {
        let names = ["New", "Seen", "Learning", "Familiar", "Strong", "Mastered"]
        let colors = [Theme.inkFaint, Theme.inkSoft, Theme.accentSoft, Theme.teal, Theme.accent, Theme.good]
        let maxIndex = min(LexemeEngine.maxLevel, min(names.count, min(colors.count, distribution.count)) - 1)
        guard maxIndex >= 0 else { return [] }
        return (0...maxIndex).map { i in
            MasterySlice(level: i, name: names[i], count: distribution[i], color: colors[i])
        }
    }

    // MARK: - Forecast

    private var forecastChart: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Due in the next 7 days")
                if isPro {
                    if forecast.reduce(0, +) == 0 {
                        miniEmpty("Nothing scheduled — you're all caught up.")
                    } else {
                        Chart(forecastData) { item in
                            BarMark(x: .value("Day", item.label), y: .value("Due", item.count))
                                .foregroundStyle(item.isToday ? Theme.accent : Theme.accent.opacity(0.55))
                                .cornerRadius(5)
                        }
                        .frame(height: 150)
                    }
                } else {
                    proLockedChart(height: 150)
                }
            }
        }
    }

    private var forecastData: [ForecastItem] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let today = cal.startOfDay(for: Date())
        let fmt = DateFormatter(); fmt.dateFormat = "EEE"
        return forecast.enumerated().map { i, count in
            let day = cal.date(byAdding: .day, value: i, to: today) ?? today
            return ForecastItem(index: i, label: i == 0 ? "Today" : fmt.string(from: day), count: count, isToday: i == 0)
        }
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Achievements")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(achievements) { a in
                        AchievementBadge(achievement: a)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func miniEmpty(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 80)
            .multilineTextAlignment(.center)
    }

    private func proLockedChart(height: CGFloat) -> some View {
        Button { showPaywall = true } label: {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 22)).foregroundStyle(Theme.gold)
                Text("Detailed charts are part of Lexeme Pro")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var proNote: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis").foregroundStyle(Theme.accent)
                Text("Unlock the full dashboard with Lexeme Pro.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chart data

/// Identifiable chart rows (key paths to tuple elements aren't valid in Swift,
/// so the chart series are backed by small Identifiable structs).
private struct LearnedPoint: Identifiable {
    let id = UUID()
    let date: Date
    let total: Int
}

private struct MasterySlice: Identifiable {
    var id: Int { level }
    let level: Int
    let name: String
    let count: Int
    let color: Color
}

private struct ForecastItem: Identifiable {
    var id: Int { index }
    let index: Int
    let label: String
    let count: Int
    let isToday: Bool
}

// MARK: - Subviews

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let tint: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(tint).accessibilityHidden(true)
            Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink).contentTransition(.numericText())
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Theme.hairline, lineWidth: 3)
                Circle()
                    .trim(from: 0, to: achievement.fraction)
                    .stroke(achievement.isUnlocked ? Theme.gold : Theme.accent,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: achievement.systemImage)
                    .font(.system(size: 15))
                    .foregroundStyle(achievement.isUnlocked ? Theme.gold : Theme.inkFaint)
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text(achievement.title)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(achievement.isUnlocked ? Theme.ink : Theme.inkSoft)
                Text(achievement.detail)
                    .font(Theme.rounded(10))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(achievement.isUnlocked ? 1 : 0.85)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(achievement.title), \(achievement.isUnlocked ? "unlocked" : "locked"). \(achievement.detail)")
    }
}
