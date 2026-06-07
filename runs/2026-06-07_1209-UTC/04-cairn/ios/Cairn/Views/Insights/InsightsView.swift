import SwiftUI
import SwiftData
import Charts

/// Catalog-level insights: where your gear weight lives, your heaviest items,
/// and how your lists compare on base weight.
struct InsightsView: View {
    @Query private var gear: [GearItem]
    @Query(sort: \PackList.createdAt) private var lists: [PackList]
    @AppStorage("cairn.unit") private var unit = "g"

    private var catalogByCat: [(category: GearCategory, grams: Double)] {
        var map: [GearCategory: Double] = [:]
        for g in gear { map[g.category, default: 0] += g.weightGrams }
        return GearCategory.allCases.compactMap { c in
            guard let v = map[c], v > 0 else { return nil }
            return (c, v)
        }.sorted { $0.grams > $1.grams }
    }
    private var heaviest: [GearItem] {
        gear.sorted { $0.weightGrams > $1.weightGrams }.prefix(6).map { $0 }
    }
    private var listBars: [ListBar] {
        lists.map { ListBar(name: $0.name, base: PackMath.weights(for: $0.entries).base) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if gear.isEmpty {
                    ScrollView {
                        EmptyStateView(icon: "chart.pie",
                                       title: "No insights yet",
                                       message: "Add gear and build a list, and Cairn will show where your weight lives and where to cut.")
                            .padding(.top, 50)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: "\(gear.count)", label: "Gear items")
                                StatTile(value: WeightFmt.compact(gear.map { $0.weightGrams }.reduce(0, +), unit: unit),
                                         label: "Total catalog")
                                StatTile(value: "\(lists.count)", label: "Lists")
                            }
                            catalogCard
                            if !listBars.isEmpty && listBars.contains(where: { $0.base > 0 }) { listCompareCard }
                            heaviestCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .background(Brand.pageBackground)
        }
    }

    private var catalogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Catalog by category")
            Chart(catalogByCat, id: \.category) { row in
                BarMark(x: .value("Grams", row.grams),
                        y: .value("Category", row.category.rawValue))
                    .foregroundStyle(row.category.tint)
                    .cornerRadius(4)
            }
            .frame(height: CGFloat(max(1, catalogByCat.count)) * 30 + 20)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Brand.hairline)
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(WeightFmt.compact(v, unit: unit)) }
                    }
                }
            }
            .accessibilityLabel("Catalog weight by category")
        }.glassCard()
    }

    private var listCompareCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Base weight by list")
            Chart(listBars) { bar in
                BarMark(x: .value("List", bar.name), y: .value("Base", bar.base))
                    .foregroundStyle(Brand.live)
                    .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Brand.hairline)
                    AxisValueLabel {
                        if let v = value.as(Double.self) { Text(WeightFmt.compact(v, unit: unit)) }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Base weight compared across lists")
        }.glassCard()
    }

    private var heaviestCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Heaviest items")
            ForEach(heaviest) { g in
                HStack(spacing: 10) {
                    Image(systemName: g.category.symbol).foregroundStyle(g.category.tint).frame(width: 22)
                        .accessibilityHidden(true)
                    Text(g.name).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(WeightFmt.string(g.weightGrams, unit: unit))
                        .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
                }
                if g.id != heaviest.last?.id { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }
}

private struct ListBar: Identifiable {
    let id = UUID()
    let name: String
    let base: Double
}
