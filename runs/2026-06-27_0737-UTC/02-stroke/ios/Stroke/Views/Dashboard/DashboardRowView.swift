import SwiftUI
import SwiftData
import Charts

struct DashboardRowView: View {
    @Query(sort: \RowWorkout.date, order: .reverse) private var workouts: [RowWorkout]
    @Query private var settings: [StrokeSettings]
    @Query private var prs: [RowPR]
    @State private var showLog = false

    private var s: StrokeSettings? { settings.first }
    private var goalM: Int { s?.weeklyDistanceGoalM ?? 20000 }
    private var displayWatts: Bool { s?.displayWatts ?? false }

    private var thisWeek: [RowWorkout] {
        let start = Calendar.current.startOfWeek(Date())
        return workouts.filter { $0.date >= start }
    }
    private var weekDistanceM: Int { thisWeek.reduce(0) { $0 + $1.distanceM } }
    private var weekProgress: Double { min(1.0, Double(weekDistanceM) / Double(goalM)) }

    private var last7: [RowWorkout] { Array(workouts.prefix(7)) }

    private var recentSplit: String {
        guard let last = workouts.first else { return "--:--" }
        return last.split500mDisplay
    }

    private var streak: Int {
        var count = 0
        var check = Calendar.current.startOfDay(Date())
        for w in workouts {
            let wDay = Calendar.current.startOfDay(w.date)
            if wDay == check { count += 1; continue }
            if let prev = Calendar.current.date(byAdding: .day, value: -1, to: check), wDay == prev {
                count += 1
                check = prev
            } else { break }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weekRing
                    quickStats
                    if !workouts.isEmpty {
                        recentWorkoutCard
                    }
                    prHighlights
                }
                .padding()
            }
            .navigationTitle("Stroke")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showLog = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Log workout")
                }
            }
            .sheet(isPresented: $showLog) { LogWorkoutView() }
        }
    }

    private var weekRing: some View {
        ZStack {
            StrokeTheme.gradient()
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: weekProgress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", Double(weekDistanceM) / 1000))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("km")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .frame(width: 100, height: 100)
                .accessibilityValue("\(Int(weekProgress * 100))% of weekly goal")
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Goal: \(goalM / 1000) km")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text("\(thisWeek.count) sessions")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Streak: \(streak) days")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            statCard("Workouts", value: "\(workouts.count)", icon: "figure.rowing", color: .teal)
            statCard("Avg Split", value: recentSplit, icon: "stopwatch", color: .orange)
            statCard("Total km", value: String(format: "%.0f", Double(workouts.reduce(0) { $0 + $1.distanceM }) / 1000), icon: "ruler", color: .cyan)
        }
    }

    private var recentWorkoutCard: some View {
        let w = workouts[0]
        return VStack(alignment: .leading, spacing: 10) {
            Label("Last Workout", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(w.workoutType.rawValue)
                        .font(.subheadline.bold())
                    Text(w.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(w.distanceDisplay)
                        .font(.title3.bold())
                    HStack(spacing: 8) {
                        Text(w.split500mDisplay + "/500m")
                        if displayWatts && w.avgWatts > 0 {
                            Text(String(format: "%.0fW", w.avgWatts))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(StrokeTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var prHighlights: some View {
        let topPRs = prs.prefix(4)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Personal Records", systemImage: "trophy.fill")
                .font(.headline)
            if prs.isEmpty {
                Text("Log workouts to set PRs")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                    ForEach(topPRs) { pr in
                        VStack(spacing: 4) {
                            Text(pr.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(pr.displayValue)
                                .font(.subheadline.bold())
                                .foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(StrokeTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(StrokeTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(StrokeTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension Calendar {
    func startOfWeek(_ date: Date) -> Date {
        var comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2
        return self.date(from: comps) ?? date
    }
}
