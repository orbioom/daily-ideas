import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(sort: \ArtSession.date, order: .forward) private var sessions: [ArtSession]
    @Query private var skills: [ArtSkill]
    @Query private var goals: [StudyGoal]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            weeklyGoalCard
                            minutesPerMonthChart
                            mediumBreakdownChart
                            moodTrendChart
                            skillsMasterySection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }

    // MARK: - Weekly Goal Card
    private var weeklyGoalCard: some View {
        let target = goals.first?.targetMinutesPerWeek ?? 300
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let actual = sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.durationMinutes }
        let progress = min(1.0, Double(actual) / Double(max(1, target)))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("This Week", systemImage: "target")
                    .font(.headline)
                Spacer()
                Text("\(actual)m / \(target)m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? AtelierTheme.sage : AtelierTheme.amber)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .clipShape(Capsule())
            Text(progress >= 1.0 ? "Goal achieved!" : "\(Int((1 - progress) * Double(target))) min to go")
                .font(.caption)
                .foregroundStyle(progress >= 1.0 ? AtelierTheme.sage : .secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly goal: \(actual) of \(target) minutes completed")
    }

    // MARK: - Minutes per Month
    private var minutesPerMonthChart: some View {
        ChartCard(title: "Practice Minutes / Month", color: AtelierTheme.amber) {
            Chart(monthlyMinutes) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(AtelierTheme.amber)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - Medium Breakdown
    private var mediumBreakdownChart: some View {
        ChartCard(title: "By Medium", color: AtelierTheme.amber) {
            HStack(spacing: 16) {
                Chart(mediumData) { item in
                    SectorMark(
                        angle: .value("Minutes", item.minutes),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.medium.color)
                    .cornerRadius(4)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(mediumData) { item in
                        HStack(spacing: 6) {
                            Circle().fill(item.medium.color).frame(width: 8, height: 8).accessibilityHidden(true)
                            Text(item.medium.rawValue).font(.caption)
                            Spacer()
                            Text("\(item.minutes)m").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mood Trend
    private var moodTrendChart: some View {
        ChartCard(title: "Session Mood", color: AtelierTheme.amber) {
            Chart(moodData) { item in
                BarMark(
                    x: .value("Mood", item.mood.rawValue),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.mood.color)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let s = value.as(String.self), let m = SessionMood.allCases.first(where: { $0.rawValue == s }) {
                            Text(m.emoji)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
    }

    // MARK: - Skills Summary
    private var skillsMasterySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills Overview")
                .font(.headline)

            ForEach(SkillStatus.allCases.reversed(), id: \.self) { status in
                let count = skills.filter { $0.status == status }.count
                if count > 0 {
                    HStack(spacing: 10) {
                        Circle().fill(status.color).frame(width: 10, height: 10).accessibilityHidden(true)
                        Text(status.rawValue).font(.subheadline)
                        Spacer()
                        Text("\(count)").font(.subheadline.bold())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(status.rawValue): \(count) skill\(count == 1 ? "" : "s")")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(AtelierTheme.amber.opacity(0.5))
                .accessibilityHidden(true)
            Text("No data yet")
                .font(.title3.bold())
            Text("Log practice sessions to see your progress here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No progress data yet. Log sessions to see charts.")
    }

    // MARK: - Computed data

    private struct MonthData: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Int
    }

    private struct MediumData: Identifiable {
        let id = UUID()
        let medium: ArtMedium
        let minutes: Int
    }

    private struct MoodData: Identifiable {
        let id = UUID()
        let mood: SessionMood
        let count: Int
    }

    private var monthlyMinutes: [MonthData] {
        let cal = Calendar.current
        var sums: [Date: Int] = [:]
        for s in sessions {
            let start = cal.startOfMonth(for: s.date)
            sums[start, default: 0] += s.durationMinutes
        }
        return sums.sorted { $0.key < $1.key }.map { MonthData(date: $0.key, minutes: $0.value) }
    }

    private var mediumData: [MediumData] {
        var sums: [ArtMedium: Int] = [:]
        for s in sessions { sums[s.medium, default: 0] += s.durationMinutes }
        return sums.sorted { $0.value > $1.value }.map { MediumData(medium: $0.key, minutes: $0.value) }
    }

    private var moodData: [MoodData] {
        var counts: [SessionMood: Int] = [:]
        for s in sessions { counts[s.mood, default: 0] += 1 }
        return SessionMood.allCases.compactMap { m in
            guard let c = counts[m], c > 0 else { return nil }
            return MoodData(mood: m, count: c)
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
