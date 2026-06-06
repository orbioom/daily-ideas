import SwiftUI
import SwiftData
import Charts

struct HarvestView: View {
    @Query(sort: \Harvest.date, order: .reverse) private var harvests: [Harvest]
    @AppStorage("massUnit") private var massRaw = MassUnit.kg.rawValue

    private var mass: MassUnit { MassUnit(rawValue: massRaw) ?? .kg }
    private var totalHoneyKg: Double { harvests.filter { $0.type == .honey }.reduce(0) { $0 + $1.weightKg } }
    private var byType: [(type: HarvestType, kg: Double)] {
        Dictionary(grouping: harvests, by: { $0.type })
            .map { (type: $0.key, kg: $0.value.reduce(0) { $0 + $1.weightKg }) }
            .sorted { $0.kg > $1.kg }
    }
    private var byYear: [(year: Int, kg: Double)] {
        Dictionary(grouping: harvests.filter { $0.type == .honey },
                   by: { Calendar.current.component(.year, from: $0.date) })
            .map { (year: $0.key, kg: $0.value.reduce(0) { $0 + $1.weightKg }) }
            .sorted { $0.year < $1.year }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if harvests.isEmpty {
                    EmptyStateView(icon: "drop",
                                   title: "No harvests yet",
                                   message: "Record honey, wax, or propolis from a hive and totals appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: mass.format(kg: totalHoneyKg), label: "Total honey", accent: Brand.warn)
                                StatTile(value: "\(harvests.count)", label: "Harvests")
                            }
                            if byYear.count >= 1 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Honey by year")
                                    Chart(byYear, id: \.year) { item in
                                        BarMark(x: .value("Year", String(item.year)),
                                                y: .value("Honey", mass.fromKg(item.kg)))
                                        .foregroundStyle(Brand.warn.gradient).cornerRadius(4)
                                    }
                                    .frame(height: 180)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "By product")
                                ForEach(byType, id: \.type) { item in
                                    HStack {
                                        Image(systemName: item.type.icon).foregroundStyle(Brand.warn)
                                            .frame(width: 24).accessibilityHidden(true)
                                        Text(item.type.rawValue).font(.subheadline).foregroundStyle(Brand.text)
                                        Spacer()
                                        Text(mass.format(kg: item.kg)).font(Brand.mono(14, weight: .semibold))
                                            .foregroundStyle(Brand.text)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                            SectionHeader(title: "All harvests")
                            LazyVStack(spacing: 8) {
                                ForEach(harvests) { h in
                                    HStack {
                                        Image(systemName: h.type.icon).foregroundStyle(Brand.warn).frame(width: 22)
                                            .accessibilityHidden(true)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(h.hive?.name ?? "Hive").font(.subheadline.weight(.medium))
                                                .foregroundStyle(Brand.text)
                                            Text("\(h.type.rawValue) · \(h.date.formatted(.dateTime.month().day().year()))")
                                                .font(.caption).foregroundStyle(Brand.text2)
                                        }
                                        Spacer()
                                        Text(mass.format(kg: h.weightKg)).font(Brand.mono(14)).foregroundStyle(Brand.text)
                                    }
                                    .glassCard(padding: 12)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Harvest")
        }
    }
}
