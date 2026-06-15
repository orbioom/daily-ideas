import SwiftUI
import SwiftData
import Charts

/// Insights: totals, gift-card balance, cards by category (Swift Charts), most-used
/// cards, and recently used. All computed in Swift from fetched data.
struct InsightsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var cards: [LoyaltyCard]
    @Query private var giftCards: [GiftCard]

    private struct CategoryCount: Identifiable {
        let category: CardCategory
        let count: Int
        var id: String { category.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if cards.isEmpty && giftCards.isEmpty {
                    EmptyStateView(symbol: "chart.bar.xaxis",
                                   title: "Nothing to chart yet",
                                   message: "Add a few cards and your wallet insights will appear here.")
                } else {
                    content
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                statsRow
                categoryChartPanel
                mostUsedPanel
                recentlyUsedPanel
            }
            .padding(16)
        }
    }

    // MARK: Stat tiles

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(cards.count)", label: "Loyalty cards", symbol: "wallet.pass.fill")
            statTile(value: isPro ? "\(giftCards.count)" : "—",
                     label: "Gift cards", symbol: "giftcard.fill")
        }
        .accessibilityElement(children: .contain)
    }

    private var balanceTile: some View {
        let total = giftCards.reduce(Decimal.zero) { $0 + $1.remainingBalance }
        return CardSurface {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gift-card balance remaining")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(isPro ? Money.string(total) : "Pro feature")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
        }
    }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                Text(label)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: Category chart

    private var categoryCounts: [CategoryCount] {
        let dict = Dictionary(grouping: cards, by: { $0.category })
        return CardCategory.allCases
            .compactMap { category -> CategoryCount? in
                guard let group = dict[category], !group.isEmpty else { return nil }
                return CategoryCount(category: category, count: group.count)
            }
            .sorted { $0.count > $1.count }
    }

    @ViewBuilder
    private var categoryChartPanel: some View {
        if !categoryCounts.isEmpty {
            CardSurface {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Cards by category", symbol: "square.grid.2x2")
                    Chart(categoryCounts) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Category", item.category.displayName)
                        )
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(5)
                        .annotation(position: .trailing) {
                            Text("\(item.count)")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(categoryCounts.count) * 32 + 10)
                    .accessibilityLabel("Bar chart of cards by category")
                }
            }
            balanceTile
        }
    }

    // MARK: Most used

    private var mostUsed: [LoyaltyCard] {
        cards.filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
    }

    @ViewBuilder
    private var mostUsedPanel: some View {
        let recent = Array(mostUsed.prefix(5))
        if !recent.isEmpty {
            CardSurface {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Recently used", symbol: "clock.arrow.circlepath")
                    ForEach(recent) { card in
                        usageRow(card)
                        if card.id != recent.last?.id {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
            }
        }
    }

    private func usageRow(_ card: LoyaltyCard) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hexString: card.colorHex, fallback: Theme.accent))
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: card.category.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hexString: card.colorHex, fallback: Theme.accent).readableForeground)
                )
                .accessibilityHidden(true)
            Text(card.displayTitle)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer()
            if let last = card.lastUsedAt {
                Text(last.formatted(.relative(presentation: .named)))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.displayTitle), used \(card.lastUsedAt?.formatted(.relative(presentation: .named)) ?? "never")")
    }

    // MARK: Newest cards

    @ViewBuilder
    private var recentlyUsedPanel: some View {
        let newest = cards.sorted { $0.createdAt > $1.createdAt }.prefix(5)
        if !newest.isEmpty {
            CardSurface {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Recently added", symbol: "sparkles")
                    ForEach(Array(newest)) { card in
                        HStack {
                            Text(card.displayTitle)
                                .font(Theme.rounded(15, .medium))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Spacer()
                            Text(card.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
            }
        }
    }
}
