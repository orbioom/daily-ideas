import SwiftUI
import SwiftData
import Charts

struct DeckStatsView: View {
    @Query private var decks: [FlashDeck]
    @AppStorage("studyStreak") private var studyStreak = 0

    private var allCards: [FlashCard] { decks.flatMap(\.cards) }
    private var totalDue: Int { allCards.filter(\.isDue).count }
    private var totalReviewed: Int { allCards.filter { $0.repetitions > 0 }.count }
    private var avgRetention: Double {
        let d = decks.filter { !$0.cards.isEmpty }
        guard !d.isEmpty else { return 0 }
        return d.reduce(0.0) { $0 + $1.retentionRate } / Double(d.count)
    }

    private var intervalDistribution: [(label: String, count: Int)] {
        var bins: [String: Int] = ["Today": 0, "1–7d": 0, "8–30d": 0, ">30d": 0]
        let now = Date()
        for card in allCards {
            let days = Calendar.current.dateComponents([.day], from: now, to: card.nextReview).day ?? 0
            if days <= 0 { bins["Today", default: 0] += 1 }
            else if days <= 7 { bins["1–7d", default: 0] += 1 }
            else if days <= 30 { bins["8–30d", default: 0] += 1 }
            else { bins[">30d", default: 0] += 1 }
        }
        return [
            (label: "Today",  count: bins["Today"] ?? 0),
            (label: "1–7d",   count: bins["1–7d"] ?? 0),
            (label: "8–30d",  count: bins["8–30d"] ?? 0),
            (label: ">30d",   count: bins[">30d"] ?? 0)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allCards.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(DeckTheme.accent.opacity(0.3))
                            .accessibilityHidden(true)
                        Text("No stats yet")
                            .font(.headline)
                            .foregroundStyle(DeckTheme.text)
                        Text("Create decks and start studying to see your progress.")
                            .font(.subheadline)
                            .foregroundStyle(DeckTheme.subtle)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    VStack(spacing: 20) {
                        overviewGrid
                        if !intervalDistribution.isEmpty { forecastChart }
                        deckBreakdown
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .background(DeckTheme.bg)
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(allCards.count)", label: "Total Cards", icon: "rectangle.stack.fill", color: DeckTheme.accent)
            StatTile(value: "\(totalDue)", label: "Due Now", icon: "clock.fill", color: totalDue > 0 ? .orange : .green)
            StatTile(value: "\(totalReviewed)", label: "Reviewed", icon: "checkmark.circle.fill", color: .green)
            StatTile(value: "\(Int(avgRetention * 100))%", label: "Avg Retention", icon: "brain.filled.head.profile", color: .purple)
        }
    }

    @ViewBuilder
    private var forecastChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cards by Due Date")
                .font(.headline)
                .foregroundStyle(DeckTheme.text)

            Chart(intervalDistribution, id: \.label) { item in
                BarMark(
                    x: .value("When", item.label),
                    y: .value("Cards", item.count)
                )
                .foregroundStyle(DeckTheme.accent.gradient)
                .cornerRadius(6)
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(DeckTheme.subtle) }
            }
        }
        .padding()
        .background(DeckTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var deckBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deck Overview")
                .font(.headline)
                .foregroundStyle(DeckTheme.text)

            ForEach(decks) { deck in
                HStack {
                    Text(deck.emoji).accessibilityHidden(true)
                    Text(deck.name)
                        .font(.subheadline)
                        .foregroundStyle(DeckTheme.text)
                    Spacer()
                    Text("\(deck.cards.count) cards")
                        .font(.caption)
                        .foregroundStyle(DeckTheme.subtle)
                    Text("·")
                        .foregroundStyle(DeckTheme.subtle.opacity(0.5))
                    Text("\(Int(deck.retentionRate * 100))%")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DeckTheme.colorFromHex(deck.colorHex))
                }
                .padding(.vertical, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(deck.name): \(deck.cards.count) cards, \(Int(deck.retentionRate * 100))% retention")
            }
        }
        .padding()
        .background(DeckTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(DeckTheme.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(DeckTheme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DeckTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
