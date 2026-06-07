import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var species: [Species]
    @Query private var sightings: [Sighting]
    @State private var stats: LifeListEngine.Stats?
    @State private var isLoading = true

    private let year = Calendar.current.component(.year, from: Date())
    private let months = ["J","F","M","A","M","J","J","A","S","O","N","D"]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 12) { ProgressView().controlSize(.large)
                        Text("Crunching the numbers…").font(.subheadline).foregroundStyle(Brand.text2) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let s = stats, s.totalSightings > 0 {
                    content(s)
                } else {
                    ScrollView {
                        EmptyStateView(icon: "chart.bar.xaxis", title: "No data yet",
                                       message: "Log some sightings to see your year list and trends.")
                        .glassCard().padding()
                    }
                }
            }
            .navigationTitle("Insights")
            .background(Brand.pageBackground)
        }
        .task(id: sightings.count) { await recompute() }
    }

    private func recompute() async {
        isLoading = true
        await Task.yield()
        stats = LifeListEngine.stats(species: species, sightings: sightings, year: year)
        isLoading = false
    }

    private func content(_ s: LifeListEngine.Stats) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                let cols = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: cols, spacing: 10) {
                    StatTile(value: "\(s.lifeSpecies)", label: "Life species")
                    StatTile(value: "\(s.yearSpecies)", label: "\(year) species", accent: Brand.live)
                    StatTile(value: "\(s.lifersThisYear)", label: "Lifers this year", accent: Brand.magic)
                    StatTile(value: "\(s.totalIndividuals)", label: "Individuals")
                }

                if !s.topSpecies.isEmpty {
                    barCard(title: "Most observed", items: s.topSpecies.map { ($0.name, $0.count) }, color: Brand.live)
                }
                if !s.byFamily.isEmpty {
                    barCard(title: "Top families", items: s.byFamily.map { ($0.name, $0.count) }, color: Brand.info)
                }
                monthCard(s)
            }
            .padding()
        }
    }

    private func barCard(title: String, items: [(String, Int)], color: Color) -> some View {
        let maxV = max(1, items.map { $0.1 }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: title)
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.0).font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                        Spacer()
                        Text("\(item.1)").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    MeterBar(fraction: Double(item.1) / Double(maxV), color: color)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.0): \(item.1)")
            }
        }
        .glassCard()
    }

    private func monthCard(_ s: LifeListEngine.Stats) -> some View {
        let maxV = max(1, s.byMonth.max() ?? 1)
        return VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Species by month")
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<12, id: \.self) { m in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3).fill(Brand.hairline).frame(height: 80)
                            RoundedRectangle(cornerRadius: 3).fill(Brand.live)
                                .frame(height: max(2, 80 * Double(s.byMonth[m]) / Double(maxV)))
                        }
                        Text(months[m]).font(Brand.mono(9)).foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityLabel("Species observed by month chart")
        }
        .glassCard()
    }
}
