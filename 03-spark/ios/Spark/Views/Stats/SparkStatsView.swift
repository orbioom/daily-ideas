import SwiftUI
import SwiftData
import Charts

struct SparkStatsView: View {
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]
    @State private var engine = FocusStatsEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        ContentUnavailableView {
                            Label("No Sessions Yet", systemImage: "bolt.circle")
                        } description: {
                            Text("Complete your first focus session to see stats here.")
                        }
                    } else {
                        summaryRow
                        weeklyChart
                        categoryChart
                        recentSessions
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statCard("bolt.circle.fill",
                     value: "\(engine.totalFocusMinutes(sessions))",
                     label: "Min Focused",
                     color: SparkTheme.electricBlue)
            statCard("checkmark.circle.fill",
                     value: String(format: "%.0f%%", engine.completionRate(sessions) * 100),
                     label: "Completion",
                     color: SparkTheme.focusGreen)
            statCard("flame.fill",
                     value: "\(engine.streakDays(sessions))",
                     label: "Day Streak",
                     color: SparkTheme.amber)
        }
    }

    private func statCard(_ icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color).accessibilityHidden(true)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var weeklyChart: some View {
        let data = engine.weeklyMinutes(sessions)
        return VStack(alignment: .leading, spacing: 8) {
            Text("This Week — Focus Minutes")
                .font(.headline)
            Chart(data, id: \.day) { item in
                BarMark(x: .value("Day", item.day), y: .value("Min", item.minutes))
                    .foregroundStyle(SparkTheme.electricBlue.gradient)
                    .cornerRadius(5)
            }
            .frame(height: 140)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Weekly focus minutes bar chart")
    }

    private var categoryChart: some View {
        let data = engine.categoryBreakdown(sessions)
        guard !data.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: 8) {
            Text("By Category")
                .font(.headline)
            Chart(data, id: \.category) { item in
                BarMark(x: .value("Cat", item.category.rawValue), y: .value("Min", item.minutes))
                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                    .cornerRadius(5)
            }
            .frame(height: 120)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Focus by category bar chart"))
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Sessions")
                .font(.headline)
            ForEach(sessions.prefix(8)) { s in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(SparkTheme.categoryColor(s.category).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: s.category.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(SparkTheme.categoryColor(s.category))
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(s.taskTitle)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(s.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(s.actualMinutes) min")
                            .font(.caption.weight(.semibold))
                        Image(systemName: s.wasCompleted ? "checkmark.circle.fill" : "xmark.circle")
                            .font(.caption)
                            .foregroundStyle(s.wasCompleted ? .green : .secondary)
                            .accessibilityLabel(s.wasCompleted ? "Completed" : "Not completed")
                    }
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
