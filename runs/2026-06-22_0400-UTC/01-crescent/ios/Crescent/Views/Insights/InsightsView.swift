import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \MoonJournalEntry.date, order: .reverse) private var entries: [MoonJournalEntry]
    @Query private var completions: [RitualCompletion]

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            streakCard
                            moodByPhaseChart
                            phaseDistributionCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("✨").font(.system(size: 60))
            Text("No Insights Yet")
                .font(.headline).foregroundColor(CrescentTheme.pearl)
            Text("Write journal entries to unlock mood insights.")
                .font(.body).foregroundColor(CrescentTheme.silver)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }

    private var streakCard: some View {
        HStack(spacing: 20) {
            statBox(value: "\(journalStreak)", label: "Day Streak")
            statBox(value: "\(entries.count)", label: "Entries")
            statBox(value: "\(completions.count)", label: "Rituals Done")
        }
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(CrescentTheme.pearl)
            Text(label)
                .font(.caption2)
                .foregroundColor(CrescentTheme.silver)
        }
        .frame(maxWidth: .infinity)
    }

    private var moodByPhaseChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Avg Mood by Phase")
                .font(.caption).tracking(1.5).foregroundColor(CrescentTheme.gold)
            Chart(moodByPhaseData, id: \.phase) { item in
                BarMark(
                    x: .value("Phase", item.phase.symbol),
                    y: .value("Mood", item.avgMood)
                )
                .foregroundStyle(CrescentTheme.gold)
                .cornerRadius(4)
                .annotation(position: .top) {
                    Text(String(format: "%.1f", item.avgMood))
                        .font(.caption2).foregroundColor(CrescentTheme.silver)
                }
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5]) { v in
                    AxisValueLabel { Text("\(v.as(Int.self) ?? 0)").foregroundColor(CrescentTheme.silver).font(.caption2) }
                }
            }
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel() }
            }
            .frame(height: 160)
        }
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }

    private var phaseDistributionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Entries by Phase")
                .font(.caption).tracking(1.5).foregroundColor(CrescentTheme.gold)
            ForEach(phaseDistributionData, id: \.phase) { item in
                HStack {
                    Text(item.phase.symbol + " " + item.phase.rawValue)
                        .font(.caption)
                        .foregroundColor(CrescentTheme.pearl)
                        .frame(width: 140, alignment: .leading)
                    GeometryReader { geo in
                        Rectangle()
                            .fill(CrescentTheme.gold.opacity(0.7))
                            .frame(width: geo.size.width * (entries.isEmpty ? 0 : CGFloat(item.count) / CGFloat(entries.count)))
                            .cornerRadius(4)
                    }
                    .frame(height: 10)
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(CrescentTheme.silver)
                        .frame(width: 24)
                }
            }
        }
        .padding()
        .background(CrescentTheme.cardBg)
        .cornerRadius(16)
    }

    struct PhaseAvgMood { let phase: MoonPhase; let avgMood: Double }
    struct PhaseCount { let phase: MoonPhase; let count: Int }

    private var moodByPhaseData: [PhaseAvgMood] {
        MoonPhase.allCases.compactMap { phase in
            let phaseEntries = entries.filter { $0.moonPhaseRaw == phase.rawValue }
            guard !phaseEntries.isEmpty else { return nil }
            let avg = Double(phaseEntries.reduce(0) { $0 + $1.moodRating }) / Double(phaseEntries.count)
            return PhaseAvgMood(phase: phase, avgMood: avg)
        }
    }

    private var phaseDistributionData: [PhaseCount] {
        MoonPhase.allCases.compactMap { phase in
            let count = entries.filter { $0.moonPhaseRaw == phase.rawValue }.count
            guard count > 0 else { return nil }
            return PhaseCount(phase: phase, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    private var journalStreak: Int {
        guard !entries.isEmpty else { return 0 }
        var streak = 0
        var current = Date()
        let cal = Calendar.current
        for entry in entries {
            if cal.isDate(entry.date, inSameDayAs: current) || 
               cal.isDate(entry.date, inSameDayAs: cal.date(byAdding: .day, value: -1, to: current) ?? current) {
                streak += 1
                current = entry.date
            } else { break }
        }
        return streak
    }
}
