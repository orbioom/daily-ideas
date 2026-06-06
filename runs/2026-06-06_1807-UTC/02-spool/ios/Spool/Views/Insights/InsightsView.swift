import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var jobs: [PrintJob]
    @Query private var spools: [Spool]
    @AppStorage("currencySymbol") private var currency = "$"
    @AppStorage("kwhRate") private var kwhRate = 0.15

    private var totalGrams: Double { jobs.reduce(0) { $0 + $1.gramsUsed } }
    private var totalCost: Double { jobs.reduce(0) { $0 + $1.totalCost(kwhRate: kwhRate) } }
    private var successRate: Double {
        guard !jobs.isEmpty else { return 0 }
        return Double(jobs.filter { $0.success }.count) / Double(jobs.count)
    }
    private var inventoryValue: Double {
        spools.filter { !$0.archived }.reduce(0) { $0 + $1.pricePerGram * $1.remainingG }
    }
    private var byMaterial: [(material: String, grams: Double)] {
        Dictionary(grouping: jobs.compactMap { j in j.spool.map { (j, $0.material.rawValue) } },
                   by: { $0.1 })
            .map { (material: $0.key, grams: $0.value.reduce(0) { $0 + $1.0.gramsUsed }) }
            .sorted { $0.grams > $1.grams }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if jobs.isEmpty && spools.isEmpty {
                    EmptyStateView(icon: "chart.pie",
                                   title: "Nothing to chart yet",
                                   message: "Add spools and log prints to see filament use and spend.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: String(format: "%.2f kg", totalGrams / 1000),
                                         label: "Filament used")
                                StatTile(value: Money.string(totalCost, symbol: currency), label: "Total spend")
                            }
                            HStack(spacing: 12) {
                                StatTile(value: "\(Int(successRate * 100))%", label: "Success rate",
                                         accent: Brand.live)
                                StatTile(value: Money.string(inventoryValue, symbol: currency),
                                         label: "Stock value", accent: Brand.info)
                            }

                            if !byMaterial.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Filament used by material")
                                    Chart(byMaterial, id: \.material) { item in
                                        BarMark(x: .value("Grams", item.grams),
                                                y: .value("Material", item.material))
                                        .foregroundStyle(Brand.info.gradient)
                                        .cornerRadius(4)
                                    }
                                    .chartXAxis { AxisMarks() }
                                    .frame(height: max(120, CGFloat(byMaterial.count) * 44))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                            }

                            if !spools.filter({ !$0.archived }).isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Spool levels")
                                    ForEach(spools.filter { !$0.archived }.sorted { $0.fractionRemaining < $1.fractionRemaining }) { s in
                                        VStack(spacing: 4) {
                                            HStack {
                                                ColorSwatch(hex: s.colorHex, size: 16)
                                                Text(s.displayName).font(.subheadline).foregroundStyle(Brand.text)
                                                    .lineLimit(1)
                                                Spacer()
                                                Text("\(Int(s.remainingG)) g").font(Brand.mono(12))
                                                    .foregroundStyle(Brand.text2)
                                            }
                                            RemainingBar(fraction: s.fractionRemaining, height: 6)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }
}
