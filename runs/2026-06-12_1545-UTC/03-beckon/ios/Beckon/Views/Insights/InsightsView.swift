import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var intentions: [Intention]

    private var series: [DayReps] {
        PracticeEngine.dailyRepSeries(intentions, days: 21)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if intentions.isEmpty {
                    EmptyStateView(symbol: "chart.line.uptrend.xyaxis",
                                   title: "Your journey starts soon",
                                   message: "Set an intention and complete a few rituals to see your streak, reps and momentum here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            trendCard
                            cyclesCard
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Journey")
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatBubble(value: "\(PracticeEngine.streak(intentions: intentions))", label: "Day streak", symbol: "flame.fill")
            StatBubble(value: "\(PracticeEngine.daysPracticed(intentions))", label: "Days practiced", symbol: "calendar")
            StatBubble(value: "\(PracticeEngine.totalReps(intentions))", label: "Total affirmations", symbol: "pencil.line")
            StatBubble(value: "\(PracticeEngine.manifestedCount(intentions))", label: "Manifested", symbol: "checkmark.seal.fill")
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reps over the last 3 weeks").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(series) { item in
                BarMark(x: .value("Day", item.day, unit: .day),
                        y: .value("Reps", item.reps))
                .foregroundStyle(Theme.goldGradient)
                .cornerRadius(4)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Bar chart of daily affirmation reps for the last three weeks")
        }
        .beckonCard()
    }

    private var cyclesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active cycles").font(.headline).foregroundStyle(Theme.textPrimary)
            let active = intentions.filter { $0.state == .active }
            if active.isEmpty {
                Text("No active intentions right now.").font(.caption).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(active) { intent in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(intent.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(intent.completedDays)/\(intent.practiceLength)")
                                .font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                        ProgressView(value: intent.cycleProgress).tint(intent.tint)
                    }
                }
            }
        }
        .beckonCard()
    }
}
