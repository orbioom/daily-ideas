import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if dreams.isEmpty {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "Insights await",
                                   message: "Record a few dreams to see your recall, lucidity rate and patterns take shape.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            recallCard
                            moodCard
                            if !techniqueRows.isEmpty { techniqueCard }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStat(value: "\(Int(DreamEngine.lucidityRate(dreams) * 100))%", label: "Lucidity rate", symbol: "sparkles", tint: Theme.lucid)
            MiniStat(value: "\(DreamEngine.recallStreak(dreams))", label: "Recall streak", symbol: "flame.fill")
            MiniStat(value: "\(dreams.count)", label: "Dreams logged", symbol: "book.closed.fill")
            MiniStat(value: String(format: "%.1f", DreamEngine.averageVividness(dreams)), label: "Avg vividness", symbol: "star.fill", tint: Theme.star)
        }
    }

    private var recallCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recall — last 21 days").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(DreamEngine.dailyCounts(dreams, days: 21)) { item in
                BarMark(x: .value("Day", item.day, unit: .day),
                        y: .value("Other", max(item.count - item.lucid, 0)))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                BarMark(x: .value("Day", item.day, unit: .day),
                        y: .value("Lucid", item.lucid))
                    .foregroundStyle(Theme.lucid)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Daily dream recall with lucid dreams highlighted")
            HStack(spacing: 14) {
                legend(Theme.accent.opacity(0.5), "Dreams")
                legend(Theme.lucid, "Lucid")
            }
            .font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .reverieCard()
    }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) { Circle().fill(c).frame(width: 9, height: 9); Text(t) }
    }

    private var moodCard: some View {
        let data = DreamEngine.moodBreakdown(dreams)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Dream moods").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart(data) { item in
                SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.58), angularInset: 2)
                    .cornerRadius(4)
                    .foregroundStyle(item.mood.color)
            }
            .frame(height: 180)
            .accessibilityLabel("Donut chart of dream moods")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(data) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.mood.color).frame(width: 9, height: 9)
                        Text(item.mood.rawValue).font(.caption).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(item.count)").font(.caption.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                    }
                }
            }
        }
        .reverieCard()
    }

    private var techniqueRows: [TechniqueStat] {
        DreamEngine.techniqueEffectiveness(dreams)
    }

    private var techniqueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's working").font(.headline).foregroundStyle(Theme.textPrimary)
            Text("Lucidity by technique you've tried").font(.caption).foregroundStyle(Theme.textSecondary)
            ForEach(techniqueRows) { row in
                HStack {
                    Text(row.technique.rawValue).font(.subheadline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(row.lucid)/\(row.total) lucid")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(row.lucid > 0 ? Theme.lucid : Theme.textSecondary)
                }
                .padding(.vertical, 3)
            }
        }
        .reverieCard()
    }
}
