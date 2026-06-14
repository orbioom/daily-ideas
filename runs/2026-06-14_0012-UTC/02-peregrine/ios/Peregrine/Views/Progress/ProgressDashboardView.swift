import SwiftUI
import SwiftData
import Charts

/// Progress / Stats: accuracy trend (line), per-continent mastery (bar),
/// most-missed countries, and achievements.
struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progress: [CountryProgress]
    @Query(sort: \QuizSession.date, order: .forward) private var sessions: [QuizSession]

    private var progressByISO: [String: Double] {
        Dictionary(progress.map { ($0.iso2, $0.mastery) }, uniquingKeysWith: { a, _ in a })
    }
    private var continentMastery: [Continent: Double] {
        Stats.continentMastery(progressByISO: progressByISO)
    }
    private var recentSessions: [QuizSession] {
        Array(sessions.suffix(12))
    }
    private var mostMissed: [(country: Country, misses: Int)] {
        progress
            .filter { $0.seen > 0 && $0.seen > $0.correct }
            .compactMap { p -> (Country, Int)? in
                guard let c = CountryData.country(for: p.iso2) else { return nil }
                return (c, p.seen - p.correct)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(6)
            .map { ($0.0, $0.1) }
    }
    private var achievements: [Achievement] {
        let totalCorrect = progress.reduce(0) { $0 + $1.correct }
        let mastered = Stats.masteredCount(progressByISO: progressByISO)
        let best = Stats.bestStreak(sessionDates: sessions.map { $0.date })
        let dailyKey = QuizEngine.dailyKey()
        let dailyDone = sessions.contains { $0.isDaily && QuizEngine.dailyKey(for: $0.date) == dailyKey }
        return Achievement.evaluate(totalCorrect: totalCorrect,
                                    masteredCount: mastered,
                                    continentMastery: continentMastery,
                                    bestStreak: best,
                                    sessionsPlayed: sessions.count,
                                    dailyDone: dailyDone)
    }
    private var hasData: Bool { !sessions.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                if hasData {
                    VStack(spacing: 18) {
                        trendCard
                        continentBarCard
                        missedCard
                        achievementsCard
                    }
                    .padding(20)
                } else {
                    EmptyStateView(systemImage: "chart.line.uptrend.xyaxis",
                                   title: "No stats yet",
                                   message: "Finish a quiz and your accuracy, mastery and achievements will appear here.")
                        .padding(.top, 60)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    // MARK: Trend

    private var trendCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Accuracy trend")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Last \(recentSessions.count) sessions")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Chart {
                    ForEach(Array(recentSessions.enumerated()), id: \.element.id) { idx, s in
                        LineMark(x: .value("Session", idx + 1),
                                 y: .value("Accuracy", s.accuracy * 100))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Session", idx + 1),
                                  y: .value("Accuracy", s.accuracy * 100))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .chartYScale(domain: 0.0...100.0)
                .chartYAxis {
                    AxisMarks(values: [0.0, 50.0, 100.0]) { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let v = value.as(Double.self) { Text("\(Int(v))%") }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 170)
                .accessibilityLabel("Accuracy over the last \(recentSessions.count) sessions")
            }
        }
    }

    // MARK: Continent bars

    private var continentBarCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mastery by continent")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                Chart {
                    ForEach(Continent.displayOrder) { c in
                        BarMark(x: .value("Mastery", (continentMastery[c] ?? 0) * 100),
                                y: .value("Continent", c.title))
                            .foregroundStyle(c.tint)
                            .cornerRadius(5)
                    }
                }
                .chartXScale(domain: 0.0...100.0)
                .chartXAxis {
                    AxisMarks(values: [0.0, 50.0, 100.0]) { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let v = value.as(Double.self) { Text("\(Int(v))%") }
                        }
                    }
                }
                .frame(height: 220)
                .accessibilityLabel("Mastery by continent bar chart")
            }
        }
    }

    // MARK: Most missed

    private var missedCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Most missed")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                if mostMissed.isEmpty {
                    Text("No misses tracked yet — nicely done.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(mostMissed, id: \.country.id) { entry in
                        HStack(spacing: 12) {
                            Text(entry.country.flag)
                                .font(.system(size: 26))
                                .accessibilityHidden(true)
                            Text(entry.country.name)
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(entry.misses) missed")
                                .font(Theme.rounded(13, .medium))
                                .foregroundStyle(Theme.bad)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.country.name), missed \(entry.misses) times")
                    }
                }
            }
        }
    }

    // MARK: Achievements

    private var achievementsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Achievements")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(achievements) { a in
                        AchievementBadge(achievement: a)
                    }
                }
            }
        }
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? Theme.accentSoft : Theme.surfaceAlt)
                    .frame(width: 48, height: 48)
                Image(systemName: achievement.systemImage)
                    .font(.title3)
                    .foregroundStyle(achievement.unlocked ? Theme.accent : Theme.inkFaint)
            }
            Text(achievement.title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(achievement.unlocked ? Theme.ink : Theme.inkSoft)
                .multilineTextAlignment(.center)
            Text(achievement.detail)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !achievement.unlocked && achievement.progress > 0 {
                ProgressView(value: achievement.progress)
                    .tint(Theme.accent)
                    .scaleEffect(x: 1, y: 0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surfaceAlt.opacity(0.5))
        )
        .opacity(achievement.unlocked ? 1 : 0.85)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(achievement.title)
        .accessibilityValue(achievement.unlocked ? "Unlocked. \(achievement.detail)" : "Locked. \(achievement.detail) \(Int(achievement.progress * 100)) percent.")
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: [CountryProgress.self, QuizSession.self], inMemory: true)
}
