import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query private var settingsQuery: [UserSettings]

    private var settings: UserSettings? { settingsQuery.first }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var totalLessons: Int {
        settings?.completedLessons.count ?? 0
    }

    private var averageScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.reduce(0) { $0 + $1.score } / sessions.count
    }

    // Last 14 days of data
    private var chartData: [DayPractice] {
        let calendar = Calendar.current
        return (0..<14).map { daysAgo -> DayPractice in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            let dayMinutes = sessions
                .filter { $0.date >= dayStart && $0.date < dayEnd }
                .reduce(0) { $0 + $1.durationSeconds } / 60
            return DayPractice(date: date, minutes: dayMinutes)
        }
        .reversed()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "flame.fill",
                            value: "\(settings?.streakCount ?? 0)",
                            label: "Day Streak",
                            color: .orange
                        )
                        StatCard(
                            icon: "clock.fill",
                            value: "\(totalMinutes)m",
                            label: "Total Time",
                            color: .blue
                        )
                        StatCard(
                            icon: "star.fill",
                            value: "\(averageScore)%",
                            label: "Avg Score",
                            color: KeysTheme.accent
                        )
                    }
                    .padding(.horizontal)

                    // Practice chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 14 Days")
                            .font(.headline)
                            .foregroundStyle(KeysTheme.text)
                            .padding(.horizontal)

                        if chartData.allSatisfy({ $0.minutes == 0 }) {
                            ChartEmptyState()
                                .padding(.horizontal)
                        } else {
                            Chart(chartData) { day in
                                BarMark(
                                    x: .value("Date", day.date, unit: .day),
                                    y: .value("Minutes", day.minutes)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [KeysTheme.accent, KeysTheme.accentLight],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .cornerRadius(4)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    AxisValueLabel(format: .dateTime.day())
                                        .font(.caption)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    AxisValueLabel()
                                        .font(.caption)
                                }
                            }
                            .frame(height: 160)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(KeysTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Module completion rings
                    ModuleCompletionSection(settings: settings)
                        .padding(.horizontal)

                    // Recent sessions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .foregroundStyle(KeysTheme.text)
                            .padding(.horizontal)

                        if sessions.isEmpty {
                            ContentUnavailableView(
                                "No Practice Yet",
                                systemImage: "pianokeys",
                                description: Text("Complete your first lesson to start tracking progress.")
                            )
                        } else {
                            ForEach(sessions.prefix(10)) { session in
                                SessionRow(session: session)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
            .background(KeysTheme.background)
            .navigationTitle("Progress")
        }
    }
}

struct DayPractice: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(KeysTheme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(KeysTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ChartEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(KeysTheme.accent.opacity(0.4))
            Text("No practice data yet")
                .font(.subheadline)
                .foregroundStyle(KeysTheme.textSecondary)
            Text("Complete lessons to see your chart here")
                .font(.caption)
                .foregroundStyle(KeysTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}

struct ModuleCompletionSection: View {
    let settings: UserSettings?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Module Completion")
                .font(.headline)
                .foregroundStyle(KeysTheme.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Curriculum.modules) { module in
                    ModuleRing(module: module, settings: settings)
                }
            }
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ModuleRing: View {
    let module: CurriculumModule
    let settings: UserSettings?

    private var completed: Int {
        module.lessons.filter { settings?.isLessonCompleted($0.id) ?? false }.count
    }
    private var total: Int { module.lessons.count }
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(module.color.opacity(0.15), lineWidth: 6)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(module.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Image(systemName: module.icon)
                    .font(.subheadline)
                    .foregroundStyle(module.color)
            }

            Text(module.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(KeysTheme.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(completed)/\(total)")
                .font(.caption2)
                .foregroundStyle(KeysTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(module.color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(module.title): \(completed) of \(total) complete")
    }
}

struct SessionRow: View {
    let session: PracticeSession

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: session.date)
    }

    private var durationString: String {
        let m = session.durationSeconds / 60
        let s = session.durationSeconds % 60
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("\(session.score)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(scoreColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.lessonTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KeysTheme.text)
                Text(session.moduleTitle)
                    .font(.caption)
                    .foregroundStyle(KeysTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(durationString)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KeysTheme.text)
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(KeysTheme.textSecondary)
            }
        }
        .padding()
        .background(KeysTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scoreColor: Color {
        switch session.score {
        case 90...100: return .green
        case 70..<90: return KeysTheme.accent
        case 50..<70: return .orange
        default: return .red
        }
    }
}
