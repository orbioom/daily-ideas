import SwiftUI
import SwiftData
import Charts

/// Aggregate learning progress: totals, maturity breakdown, per-deck mastery,
/// and an upcoming-reviews forecast.
struct StatsView: View {
    @Query(sort: \Deck.sortIndex) private var decks: [Deck]

    private var allPhrases: [Phrase] { decks.flatMap(\.phrases) }
    private var overall: DeckProgress { DeckProgress.make(phrases: allPhrases) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private var content: some View {
        if allPhrases.isEmpty {
            EmptyStateView(
                symbol: "chart.bar.xaxis",
                title: "No data yet",
                message: "Study some phrases and your progress will appear here."
            )
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    summaryCards
                    maturityCard
                    perDeckCard
                    forecastCard
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    // MARK: Summary
    private var summaryCards: some View {
        HStack(spacing: Theme.Spacing.md) {
            SummaryTile(value: "\(overall.total)", label: "Phrases", symbol: "text.bubble.fill", tint: Theme.brandDeep)
            SummaryTile(value: "\(overall.masteredCount)", label: "Mastered", symbol: "checkmark.seal.fill", tint: Theme.success)
            SummaryTile(value: "\(overall.dueCount)", label: "Due", symbol: "clock.fill", tint: Theme.warn)
        }
    }

    // MARK: Maturity donut
    private var maturityCard: some View {
        let data = [
            MaturitySlice(label: "New", count: overall.newCount, color: Theme.textSecondary),
            MaturitySlice(label: "Learning", count: overall.learningCount, color: Theme.warn),
            MaturitySlice(label: "Mastered", count: overall.masteredCount, color: Theme.success)
        ].filter { $0.count > 0 }

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Maturity").font(.headline).foregroundStyle(Theme.textPrimary)
            if data.isEmpty {
                Text("Start studying to see your breakdown.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                Chart(data) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.color)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .accessibilityLabel("Maturity breakdown: \(overall.newCount) new, \(overall.learningCount) learning, \(overall.masteredCount) mastered")

                HStack(spacing: Theme.Spacing.lg) {
                    ForEach(data) { slice in
                        Label(slice.label, systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundStyle(slice.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: Per-deck mastery bars
    private var perDeckCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Mastery by deck").font(.headline).foregroundStyle(Theme.textPrimary)
            Chart {
                ForEach(decks) { deck in
                    let p = DeckProgress.make(phrases: deck.phrases)
                    BarMark(
                        x: .value("Mastery", p.masteryFraction * 100),
                        y: .value("Deck", deck.name)
                    )
                    .foregroundStyle(Theme.brand)
                    .cornerRadius(5)
                    .annotation(position: .trailing) {
                        Text("\(Int(p.masteryFraction * 100))%")
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .chartXScale(domain: 0...100)
            .frame(height: CGFloat(max(1, decks.count)) * 44)
            .accessibilityLabel("Mastery percentage by deck")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: Forecast (due over next 7 days)
    private var forecastCard: some View {
        let buckets = forecastBuckets()
        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Upcoming reviews").font(.headline).foregroundStyle(Theme.textPrimary)
            Text("Cards becoming due over the next week")
                .font(.caption).foregroundStyle(Theme.textSecondary)
            Chart(buckets) { bucket in
                BarMark(
                    x: .value("Day", bucket.label),
                    y: .value("Cards", bucket.count)
                )
                .foregroundStyle(Theme.brandDeep)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .accessibilityLabel("Upcoming reviews forecast for the next seven days")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func forecastBuckets() -> [ForecastBucket] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var counts = Array(repeating: 0, count: 7)
        for phrase in allPhrases {
            guard let state = phrase.reviewState, state.totalReviews > 0 else { continue }
            let dueDay = cal.startOfDay(for: state.dueDate)
            let diff = cal.dateComponents([.day], from: today, to: dueDay).day ?? 0
            let clamped = max(0, diff)
            if clamped < 7 { counts[clamped] += 1 }
        }
        let labels = ["Today", "1d", "2d", "3d", "4d", "5d", "6d"]
        return (0..<7).map { ForecastBucket(label: labels[$0], count: counts[$0]) }
    }
}

private struct MaturitySlice: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color
}

private struct ForecastBucket: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

private struct SummaryTile: View {
    let value: String
    let label: String
    let symbol: String
    let tint: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(tint).accessibilityHidden(true)
            Text(value).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .cardSurface(padding: 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        StatsView().modelContainer(container)
    }
}
