import SwiftUI
import SwiftData
import Charts

/// The progress board for the active challenge: a day grid colored by status,
/// summary stat tiles, and a per-week passed-vs-required bar chart.
/// Named `ProgressBoardView` to avoid clashing with SwiftUI.ProgressView.
struct ProgressBoardView: View {
    @Query(filter: #Predicate<Challenge> { $0.isActive == true })
    private var activeChallenges: [Challenge]

    private var active: Challenge? { activeChallenges.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let challenge = active {
                    ActiveProgressContent(challenge: challenge)
                } else {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No active challenge",
                        message: "Start a program in the Challenges tab to see your day-by-day progress here."
                    )
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Progress")
    }
}

private struct ActiveProgressContent: View {
    let challenge: Challenge

    @State private var now = Date()

    private var prog: ChallengeEngine.Progress {
        ChallengeEngine.progress(for: challenge, now: now)
    }

    var body: some View {
        VStack(spacing: 18) {
            statTiles
            gridCard
            weeklyChartCard
        }
        .onAppear { now = Date() }
    }

    private var statTiles: some View {
        let best = ChallengeEngine.bestStreak(for: challenge, now: now)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(prog.dayIndex)", label: "Current day", tint: Brand.text)
            StatTile(value: "\(prog.passedDays)", label: "Days passed", tint: Brand.live)
            StatTile(value: "\(best)", label: "Best streak", tint: Brand.magic)
            StatTile(value: "\(Int(prog.percent * 100))%", label: "Complete", tint: Brand.info)
        }
    }

    private var gridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Day grid")
            DayGrid(challenge: challenge, now: now, columns: 7)
            legend
        }
        .glassCard()
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Brand.live, label: "Passed")
            legendItem(color: Brand.magic, label: "Today")
            legendItem(color: Brand.danger, label: "Missed")
            legendItem(color: Brand.hairline, label: "Future")
        }
        .font(Brand.mono(10, weight: .medium))
        .foregroundStyle(Brand.text3)
        .accessibilityHidden(true)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(label)
        }
    }

    private var weeklyChartCard: some View {
        let weeks = weeklyData()
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Passed days per week")
            if weeks.isEmpty {
                Text("No days logged yet.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                Chart(weeks) { week in
                    BarMark(
                        x: .value("Week", "W\(week.week)"),
                        y: .value("Passed", week.passed)
                    )
                    .foregroundStyle(Brand.live)
                    .cornerRadius(4)
                    RuleMark(y: .value("Target", week.required))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(Brand.text3.opacity(0.5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                .accessibilityLabel("Bar chart of passed days per week against the target of seven days each.")
            }
        }
        .glassCard()
    }

    private struct WeekPoint: Identifiable {
        let id = UUID()
        let week: Int
        let passed: Int
        let required: Int
    }

    private func weeklyData() -> [WeekPoint] {
        let total = prog.dayIndex
        guard total > 0 else { return [] }
        let requiredTasks = challenge.orderedTasks.count
        var points: [WeekPoint] = []
        var week = 1
        var day = 1
        while day <= total {
            let end = min(day + 6, total)
            var passed = 0
            for d in day...end {
                if let log = ChallengeEngine.log(for: d, in: challenge.dayLogs),
                   ChallengeEngine.isDayPassed(log, requiredCount: requiredTasks) {
                    passed += 1
                }
            }
            points.append(WeekPoint(week: week, passed: passed, required: end - day + 1))
            day = end + 1
            week += 1
        }
        return points
    }
}

/// A wrapped grid of day cells colored by status. Leading blanks align Day 1 to
/// the configured week start.
private struct DayGrid: View {
    let challenge: Challenge
    let now: Date
    let columns: Int

    @AppStorage("mettle.weekStartsMonday") private var weekStartsMonday = false

    private let cellSize: CGFloat = 30

    var body: some View {
        let layout = Array(repeating: GridItem(.flexible(), spacing: 6), count: columns)
        return LazyVGrid(columns: layout, spacing: 6) {
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: cellSize)
            }
            ForEach(1...max(challenge.durationDays, 1), id: \.self) { day in
                cell(for: day)
            }
        }
    }

    private var leadingBlanks: Int {
        guard let start = challenge.startDate else { return 0 }
        var cal = Calendar.current
        cal.firstWeekday = weekStartsMonday ? 2 : 1
        let weekday = cal.component(.weekday, from: cal.startOfDay(for: start))
        // Convert to 0-based offset from the configured first weekday.
        let offset = (weekday - cal.firstWeekday + 7) % 7
        return offset
    }

    private func cell(for day: Int) -> some View {
        let status = ChallengeEngine.status(of: day, challenge: challenge,
                                            logs: challenge.dayLogs, now: now)
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(color(for: status))
            .frame(height: cellSize)
            .overlay(
                Text("\(day)")
                    .font(Brand.mono(10, weight: .medium))
                    .foregroundStyle(textColor(for: status))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Day \(day), \(label(for: status))")
    }

    private func color(for status: ChallengeEngine.DayStatus) -> Color {
        switch status {
        case .passed: return Brand.live
        case .failed: return Brand.danger
        case .pending: return Brand.magic
        case .future: return Brand.hairline
        }
    }

    private func textColor(for status: ChallengeEngine.DayStatus) -> Color {
        switch status {
        case .future: return Brand.text3
        default: return .white
        }
    }

    private func label(for status: ChallengeEngine.DayStatus) -> String {
        switch status {
        case .passed: return "passed"
        case .failed: return "missed"
        case .pending: return "today, in progress"
        case .future: return "upcoming"
        }
    }
}
