import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var marks: [VisitMark]
    @AppStorage("sojourn.countTransit") private var countTransit = false
    @AppStorage("sojourn.homeCode") private var homeCode = ""

    private var home: String? { homeCode.isEmpty ? nil : homeCode }

    private var progress: SojournEngine.WorldProgress {
        SojournEngine.worldProgress(marks, countTransit: countTransit, homeCode: home)
    }
    private var yearPoints: [SojournEngine.YearPoint] {
        SojournEngine.visitedByYear(marks, countTransit: countTransit)
    }
    private var distribution: [SojournEngine.StatusSlice] {
        SojournEngine.statusDistribution(marks)
    }
    private var continents: [SojournEngine.ContinentProgress] {
        SojournEngine.continentBreakdown(marks, countTransit: countTransit, homeCode: home)
    }
    private var passport: SojournEngine.Passport { SojournEngine.passport(marks) }
    private var thisYear: Int { SojournEngine.groundedThisYear(marks, countTransit: countTransit) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if marks.isEmpty {
                    EmptyStateView(icon: "chart.pie",
                                   title: "Nothing to chart yet",
                                   message: "Mark a few countries and your timeline, continents, and status mix will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        if !yearPoints.isEmpty { yearChart }
                        if !distribution.isEmpty { statusChart }
                        continentChart
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(Int((progress.percent * 100).rounded()))%", label: "Of the world", tint: Brand.magic)
            StatTile(value: "\(progress.continentsTouched)/\(progress.continentTotal)", label: "Continents")
            StatTile(value: "\(thisYear)", label: "New this year", tint: Brand.live)
            StatTile(value: "\(passport.favorites)", label: "Favorites", tint: Brand.warn)
        }
    }

    // MARK: Charts

    private var yearChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Countries by first-visit year")
            Chart(yearPoints) { point in
                BarMark(
                    x: .value("Year", String(point.year)),
                    y: .value("Countries", point.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis { AxisMarks(position: .leading) { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Bar chart of countries by first-visit year")
        }
        .glassCard()
    }

    private var statusChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Status mix")
            Chart(distribution) { slice in
                SectorMark(
                    angle: .value("Count", slice.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .cornerRadius(4)
                .foregroundStyle(slice.status.tint)
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .center)
            .accessibilityLabel("Donut chart of country status mix")

            // Text legend mirrors the donut for VoiceOver and clarity.
            FlowLayout(spacing: 8) {
                ForEach(distribution) { slice in
                    TagChip(text: "\(slice.status.label) \(slice.count)",
                            systemImage: slice.status.symbol,
                            tint: slice.status.tint)
                }
            }
        }
        .glassCard()
    }

    private var continentChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Visited per continent")
            Chart(continents) { c in
                BarMark(
                    x: .value("Visited", c.grounded),
                    y: .value("Continent", c.continent.label)
                )
                .foregroundStyle(c.continent.tint.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(c.grounded)/\(c.total)")
                        .font(Brand.mono(11))
                        .foregroundStyle(Brand.text3)
                }
            }
            .frame(height: CGFloat(continents.count * 34 + 20))
            .chartXAxis { AxisMarks { _ in AxisGridLine(); AxisValueLabel() } }
            .accessibilityLabel("Bar chart of countries visited per continent")
        }
        .glassCard()
    }
}
