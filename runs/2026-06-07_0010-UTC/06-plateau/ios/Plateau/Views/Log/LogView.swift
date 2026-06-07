import SwiftUI
import SwiftData
import Charts

struct LogView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true
    @Query(sort: \Cook.startedAt, order: .reverse) private var cooks: [Cook]

    private var done: [Cook] { cooks.filter { $0.state == .done } }

    private var avgRating: Double {
        let rated = done.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
    }

    private struct CatBar: Identifiable {
        let category: String; let count: Int
        var id: String { category }
    }
    private var catBars: [CatBar] {
        var counts: [String: Int] = [:]
        for c in done where !c.category.isEmpty { counts[c.category, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.map { CatBar(category: $0.key, count: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if done.isEmpty {
                        ScrollView {
                            EmptyStateView(icon: "list.bullet.rectangle",
                                           title: "No cooks logged yet",
                                           message: "Finished cooks land here. Rate them and mark favorites to remember what worked.")
                                .padding(.top, 60)
                        }
                    } else {
                        List {
                            summaryRow
                            if !catBars.isEmpty { chartRow }
                            ForEach(done) { c in
                                NavigationLink { CookDetailView(cook: c) } label: { CookRow(cook: c, useMetric: useMetric) }
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                            }
                            .onDelete(perform: delete)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Cook log")
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(done.count)", label: "Cooks")
            StatTile(value: "\(done.filter(\.isFavorite).count)", label: "Favorites", accent: Brand.warn)
            StatTile(value: avgRating > 0 ? String(format: "%.1f", avgRating) : "—",
                     label: "Avg rating", accent: Brand.live)
        }
        .listRowBackground(Color.clear).listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 10, trailing: 0))
    }

    private var chartRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "By category")
            Chart(catBars) { bar in
                BarMark(x: .value("Category", bar.category), y: .value("Cooks", bar.count))
                    .foregroundStyle(Brand.warn).cornerRadius(3)
            }
            .chartYAxis { AxisMarks(values: .automatic(desiredCount: 3)) }
            .frame(height: 150)
            .accessibilityLabel("Cooks logged in each category")
        }
        .glassCard()
        .listRowBackground(Color.clear).listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(done[i]) }
        try? context.save(); Haptics.tap()
    }
}

struct CookRow: View {
    let cook: Cook
    let useMetric: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cook.foodName).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if cook.isFavorite {
                    Image(systemName: "star.fill").font(.caption).foregroundStyle(Brand.warn)
                        .accessibilityLabel("Favorite")
                }
            }
            HStack(spacing: 8) {
                Chip(text: TempFmt.temp(cook.bathC, metric: useMetric), system: "thermometer.medium")
                Chip(text: TempFmt.duration(cook.totalMinutes), system: "clock")
                if cook.pasteurizeMinutes > 0 {
                    Chip(text: "pasteurized", system: "checkmark.shield", tint: Brand.live)
                }
            }
            HStack {
                Text(Fmt.date(cook.startedAt)).font(.caption).foregroundStyle(Brand.text3)
                Spacer()
                if cook.rating > 0 { StarRating(value: cook.rating) }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(cook.foodName), \(TempFmt.temp(cook.bathC, metric: useMetric)), \(Fmt.date(cook.startedAt))")
    }
}
