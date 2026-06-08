import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(filter: #Predicate<ClothingItem> { !$0.archived }) private var items: [ClothingItem]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("neglectDays") private var neglectDays = 60

    private let engine = WardrobeEngine()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if items.isEmpty {
                    EmptyStateView(icon: "chart.bar", title: "No insights yet",
                                   message: "Add pieces and log wears to see your wardrobe value, cost-per-wear, and what you actually reach for.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statTiles
                            categoryCard
                            bestValueCard
                            mostWornCard
                            neglectedCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statTiles: some View {
        let value = engine.totalValue(items)
        let wears = engine.totalWears(items)
        let avgCPW = engine.averageCostPerWear(items)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            tile("\(items.count)", "pieces", "square.grid.2x2.fill")
            tile(Money.compact(value, code: currency), "wardrobe value", "tag.fill")
            tile("\(wears)", "total wears", "arrow.triangle.2.circlepath")
            tile(avgCPW.map { Money.precise($0, code: currency) } ?? "—", "avg cost/wear", "chart.line.downtrend.xyaxis")
        }
    }

    private func tile(_ v: String, _ l: String, _ s: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: s).font(.title3).foregroundStyle(Color.accentColor)
            Text(v).font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.text).minimumScaleFactor(0.6).lineLimit(1)
            Text(l).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 14)
        .accessibilityElement(children: .combine).accessibilityLabel("\(v) \(l)")
    }

    private var categoryCard: some View {
        let cats = engine.byCategory(items)
        return VStack(alignment: .leading, spacing: 12) {
            Text("By category").font(.headline).foregroundStyle(Brand.text)
            Chart(cats) { c in
                SectorMark(angle: .value("Count", c.count), innerRadius: .ratio(0.6), angularInset: 1.5)
                    .foregroundStyle(by: .value("Category", c.category.label))
                    .cornerRadius(3)
            }
            .frame(height: 170)
            ForEach(cats) { c in
                HStack {
                    Image(systemName: c.category.symbol).font(.caption).foregroundStyle(Brand.text2).frame(width: 22)
                    Text(c.category.label).font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(c.count)").font(Brand.mono(12, weight: .medium)).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    private var bestValueCard: some View {
        let best = engine.bestValue(items)
        return rankCard(title: "Best value (cost per wear)", icon: "star.fill", rows: best.map {
            ($0, $0.costPerWear.map { Money.precise($0, code: currency) } ?? "—")
        })
    }

    private var mostWornCard: some View {
        let most = engine.mostWorn(items)
        return rankCard(title: "Most worn", icon: "flame.fill", rows: most.map {
            ($0, "\($0.wearCount)×")
        })
    }

    private var neglectedCard: some View {
        let neglected = engine.neglected(items, days: neglectDays)
        return Group {
            if neglected.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Neglected — not worn in \(neglectDays) days").font(.headline).foregroundStyle(Brand.text)
                    ForEach(neglected.prefix(6)) { item in
                        HStack(spacing: 12) {
                            ItemSwatch(colorHex: item.colorHex, symbol: item.category.symbol, size: 40, corner: 9)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name.isEmpty ? "Untitled" : item.name)
                                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                                Text(item.lastWorn.map { "Last worn \(Format.shortDate.string(from: $0))" } ?? "Never worn")
                                    .font(.caption).foregroundStyle(Brand.text3)
                            }
                            Spacer()
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    private func rankCard(title: String, icon: String, rows: [(ClothingItem, String)]) -> some View {
        Group {
            if rows.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title).font(.headline).foregroundStyle(Brand.text)
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 12) {
                            ItemSwatch(colorHex: row.0.colorHex, symbol: row.0.category.symbol, size: 40, corner: 9)
                            Text(row.0.name.isEmpty ? "Untitled" : row.0.name)
                                .font(.subheadline).foregroundStyle(Brand.text).lineLimit(1)
                            Spacer()
                            Text(row.1).font(Brand.mono(13, weight: .medium)).foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .glassCard()
            }
        }
    }
}
