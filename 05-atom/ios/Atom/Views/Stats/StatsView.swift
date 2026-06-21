import SwiftUI
import Charts
import SwiftData

struct StatsView: View {
    @Query private var progressList: [AtomProgress]
    @Query private var prefsList: [AtomPrefs]
    @Environment(\.modelContext) private var modelContext

    private var progress: AtomProgress {
        if let p = progressList.first { return p }
        let p = AtomProgress(); modelContext.insert(p); return p
    }
    private var prefs: AtomPrefs {
        if let p = prefsList.first { return p }
        let p = AtomPrefs(); modelContext.insert(p); return p
    }

    private var sessions: [AtomProgress.QuizSessionRecord] { progress.last10Sessions }
    private var hasData: Bool { !progress.sessions.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !hasData {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        // Overview cards
                        overviewSection

                        // Accuracy chart
                        accuracyChartSection

                        // Per-mode breakdown
                        modeBreakdownSection

                        // Most missed elements
                        if !topMissed.isEmpty {
                            missedElementsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(AtomTheme.background)
            .navigationTitle("Stats")
        }
    }

    // MARK: - Sections

    private var overviewSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                icon: "checkmark.circle.fill",
                iconColor: AtomTheme.success,
                label: "Total Correct",
                value: "\(progress.totalCorrect)"
            )
            StatCard(
                icon: "percent",
                iconColor: AtomTheme.accent,
                label: "Accuracy",
                value: String(format: "%.0f%%", progress.overallAccuracy)
            )
            StatCard(
                icon: "flame.fill",
                iconColor: AtomTheme.warning,
                label: "Best Streak",
                value: "\(progress.bestStreak)"
            )
            StatCard(
                icon: "list.bullet.clipboard",
                iconColor: AtomTheme.accentSecondary,
                label: "Quizzes",
                value: "\(progress.quizzesCompleted)"
            )
        }
    }

    private var accuracyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accuracy (Last 10 Sessions)")
                .font(.headline)
                .foregroundStyle(AtomTheme.textPrimary)

            if sessions.count < 2 {
                Text("Complete more quizzes to see your trend")
                    .font(.caption)
                    .foregroundStyle(AtomTheme.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                    .background(AtomTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
            } else {
                Chart {
                    ForEach(Array(sessions.enumerated()), id: \.offset) { idx, session in
                        LineMark(
                            x: .value("Session", idx + 1),
                            y: .value("Accuracy", session.accuracy)
                        )
                        .foregroundStyle(AtomTheme.accent)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Session", idx + 1),
                            y: .value("Accuracy", session.accuracy)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AtomTheme.accent.opacity(0.3), AtomTheme.accent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Session", idx + 1),
                            y: .value("Accuracy", session.accuracy)
                        )
                        .foregroundStyle(AtomTheme.accent)
                        .symbolSize(30)
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisTick().foregroundStyle(AtomTheme.textTertiary)
                        AxisGridLine().foregroundStyle(AtomTheme.cellBorder)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { val in
                        AxisTick().foregroundStyle(AtomTheme.textTertiary)
                        AxisGridLine().foregroundStyle(AtomTheme.cellBorder)
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text("\(Int(v))%")
                                    .font(.caption2)
                                    .foregroundStyle(AtomTheme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 160)
                .padding(16)
                .background(AtomTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
            }
        }
    }

    private var modeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Mode")
                .font(.headline)
                .foregroundStyle(AtomTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(QuizEngine.QuizMode.allCases.enumerated()), id: \.element.rawValue) { idx, mode in
                    let acc = progress.accuracy(for: mode)
                    let locked = mode.isPro && !prefs.isPro

                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: mode.icon)
                                .foregroundStyle(AtomTheme.accent)
                                .frame(width: 24)
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(locked ? AtomTheme.textTertiary : AtomTheme.textPrimary)
                            Spacer()
                            if locked {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(AtomTheme.textTertiary)
                            } else {
                                Text(acc > 0 ? String(format: "%.0f%%", acc) : "—")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(acc > 0 ? AtomTheme.accent : AtomTheme.textTertiary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if acc > 0 && !locked {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(AtomTheme.background)
                                        .frame(height: 3)
                                    Rectangle()
                                        .fill(AtomTheme.accent)
                                        .frame(width: geo.size.width * (acc / 100), height: 3)
                                }
                            }
                            .frame(height: 3)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }

                        if idx < QuizEngine.QuizMode.allCases.count - 1 {
                            Divider().background(AtomTheme.cellBorder).padding(.horizontal, 16)
                        }
                    }
                }
            }
            .background(AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
        }
    }

    private var topMissed: [Element] {
        progress.topMissedElementIds(limit: 5)
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { Element.element(withNumber: $0.key) }
    }

    private var missedElementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Missed")
                .font(.headline)
                .foregroundStyle(AtomTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(topMissed) { el in
                        NavigationLink {
                            ElementDetailView(element: el)
                        } label: {
                            VStack(spacing: 4) {
                                ElementCellView(element: el, width: 52, height: 62)
                                Text(el.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(AtomTheme.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 52)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(16)
            .background(AtomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundStyle(AtomTheme.textTertiary)
            Text("No Stats Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AtomTheme.textSecondary)
            Text("Take a quiz to see your stats!")
                .font(.subheadline)
                .foregroundStyle(AtomTheme.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(AtomTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(AtomTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(AtomTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [AtomProgress.self, AtomPrefs.self])
        .preferredColorScheme(.dark)
}
