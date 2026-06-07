import SwiftUI
import SwiftData
import Charts

struct HarvestView: View {
    @Query(sort: \Planting.sowDate) private var plantings: [Planting]

    private var thisYear: [Planting] {
        plantings.filter { $0.year == Season.currentYear }
    }

    private var readySoon: [Planting] {
        let horizon = FrostMath.addDays(21, to: .now)
        return thisYear.filter {
            $0.status != .harvested &&
            $0.harvestDate >= Calendar.current.startOfDay(for: .now) &&
            $0.harvestDate <= horizon
        }
        .sorted { $0.harvestDate < $1.harvestDate }
    }

    private struct MonthBar: Identifiable {
        let month: Int; let count: Int
        var id: Int { month }
        var label: String {
            DateFormatter().shortMonthSymbols[max(0, min(11, month - 1))]
        }
    }

    private var monthBars: [MonthBar] {
        var counts: [Int: Int] = [:]
        for p in thisYear {
            let m = Calendar.current.component(.month, from: p.harvestDate)
            counts[m, default: 0] += 1
        }
        return (1...12).map { MonthBar(month: $0, count: counts[$0] ?? 0) }
    }

    /// Plantings grouped by harvest month, months with content only.
    private var grouped: [(Int, [Planting])] {
        let dict = Dictionary(grouping: thisYear) {
            Calendar.current.component(.month, from: $0.harvestDate)
        }
        return dict.sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.harvestDate < $1.harvestDate }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    if thisYear.isEmpty {
                        EmptyStateView(icon: "basket",
                                       title: "No harvests scheduled",
                                       message: "Add plantings and Tilth forecasts when each one comes ready across the season.")
                            .padding(.top, 50)
                    } else {
                        VStack(spacing: 18) {
                            if !readySoon.isEmpty { readyCard }
                            chartCard
                            ForEach(grouped, id: \.0) { month, items in
                                monthSection(month, items)
                            }
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                    }
                }
            }
            .navigationTitle("Harvest")
        }
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ready soon", trailing: "next 3 weeks")
            ForEach(readySoon) { p in
                HStack {
                    Image(systemName: p.category.symbol).foregroundStyle(Brand.magic)
                        .frame(width: 24).accessibilityHidden(true)
                    Text(p.cropName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                    Spacer()
                    Text(Fmt.date(p.harvestDate)).font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.magic)
                }
                .glassCard(padding: 12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(p.cropName) ready around \(Fmt.dateLong(p.harvestDate))")
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Harvests by month")
            Chart(monthBars) { bar in
                BarMark(x: .value("Month", bar.label),
                        y: .value("Harvests", bar.count))
                .foregroundStyle(Brand.live)
                .cornerRadius(3)
            }
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            .frame(height: 170)
            .accessibilityLabel("Number of crops harvesting in each month")
        }
        .glassCard()
    }

    private func monthSection(_ month: Int, _ items: [Planting]) -> some View {
        let name = DateFormatter().monthSymbols[max(0, min(11, month - 1))]
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: name, trailing: "\(items.count)")
            ForEach(items) { p in
                HStack {
                    Image(systemName: p.category.symbol).foregroundStyle(Brand.text2)
                        .frame(width: 24).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.cropName).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Text(p.bed?.name ?? "Unassigned").font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    Text(Fmt.date(p.harvestDate)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                .glassCard(padding: 12)
            }
        }
    }
}
