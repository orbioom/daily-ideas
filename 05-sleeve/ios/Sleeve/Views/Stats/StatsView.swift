import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var cards: [Card]
    @Query private var decks: [Deck]
    @Query private var wants: [WantCard]

    var totalValue: Double {
        cards.reduce(0) { $0 + $1.totalValue }
    }

    var totalCardCount: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }

    var cardsByGame: [(game: String, count: Int)] {
        let grouped = Dictionary(grouping: cards, by: \.game)
        return grouped.map { (game: $0.key, count: $0.value.reduce(0) { $0 + $1.quantity }) }
            .sorted { $0.count > $1.count }
    }

    var cardsByRarity: [(rarity: String, count: Int)] {
        let grouped = Dictionary(grouping: cards, by: \.rarity)
        let order = CardRarity.allCases.map(\.rawValue)
        return grouped.map { (rarity: $0.key, count: $0.value.reduce(0) { $0 + $1.quantity }) }
            .sorted { (order.firstIndex(of: $0.rarity) ?? 99) < (order.firstIndex(of: $1.rarity) ?? 99) }
    }

    var topValueCards: [Card] {
        Array(cards.sorted { $0.totalValue > $1.totalValue }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Hero stats
                        HStack(spacing: 12) {
                            StatHeroCard(
                                value: "\(totalCardCount)",
                                label: "Total Cards",
                                icon: "rectangle.on.rectangle.angled",
                                color: SleeveTheme.accent
                            )
                            StatHeroCard(
                                value: "$\(String(format: "%.0f", totalValue))",
                                label: "Est. Value",
                                icon: "dollarsign.circle",
                                color: SleeveTheme.gold
                            )
                        }

                        HStack(spacing: 12) {
                            StatHeroCard(
                                value: "\(decks.count)",
                                label: "Decks",
                                icon: "rectangle.stack",
                                color: SleeveTheme.silver
                            )
                            StatHeroCard(
                                value: "\(wants.filter { !$0.isAcquired }.count)",
                                label: "Wants",
                                icon: "heart",
                                color: Color(red: 0.95, green: 0.35, blue: 0.55)
                            )
                        }

                        // Cards by game
                        if !cardsByGame.isEmpty {
                            StatSection(title: "By Game") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(cardsByGame, id: \.game) { item in
                                            VStack(spacing: 6) {
                                                Text("\(item.count)")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                Text(item.game)
                                                    .font(.caption2)
                                                    .foregroundStyle(SleeveTheme.subtleText)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                            }
                                            .frame(width: 90)
                                            .padding(.vertical, 12)
                                            .background(SleeveTheme.cardBg)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.horizontal, -20)
                            }
                        }

                        // By rarity
                        if !cardsByRarity.isEmpty {
                            StatSection(title: "By Rarity") {
                                VStack(spacing: 8) {
                                    ForEach(cardsByRarity, id: \.rarity) { item in
                                        RarityBar(
                                            rarity: item.rarity,
                                            count: item.count,
                                            total: totalCardCount
                                        )
                                    }
                                }
                            }
                        }

                        // Top value cards
                        if !topValueCards.isEmpty {
                            StatSection(title: "Most Valuable") {
                                VStack(spacing: 8) {
                                    ForEach(Array(topValueCards.enumerated()), id: \.element.persistentModelID) { index, card in
                                        HStack {
                                            Text("#\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(index == 0 ? SleeveTheme.gold : SleeveTheme.subtleText)
                                                .frame(width: 28)

                                            Circle()
                                                .fill(SleeveTheme.rarityColorFromString(card.rarity))
                                                .frame(width: 6, height: 6)

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(card.name)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.white)
                                                Text(card.setName.isEmpty ? card.game : card.setName)
                                                    .font(.caption2)
                                                    .foregroundStyle(SleeveTheme.subtleText)
                                            }

                                            Spacer()

                                            Text("$\(card.totalValue, specifier: "%.2f")")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(SleeveTheme.gold)
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(SleeveTheme.cardBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }

                        // Placeholder for growth
                        StatSection(title: "Collection Growth") {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundStyle(SleeveTheme.subtleText)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Coming Soon")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Text("Track how your collection grows over time")
                                        .font(.caption)
                                        .foregroundStyle(SleeveTheme.subtleText)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(SleeveTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sub Views

struct StatHeroCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(SleeveTheme.subtleText)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(SleeveTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .sleeveSectionHeader()
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RarityBar: View {
    let rarity: String
    let count: Int
    let total: Int

    var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(SleeveTheme.rarityColorFromString(rarity))
                .frame(width: 8, height: 8)

            Text(rarity)
                .font(.caption)
                .foregroundStyle(SleeveTheme.silver)
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SleeveTheme.darkBg)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SleeveTheme.rarityColorFromString(rarity))
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

#Preview {
    StatsView()
}
