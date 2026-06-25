import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \Observation.date, order: .forward) private var observations: [Observation]
    @Query(sort: \FieldTrip.date, order: .forward) private var trips: [FieldTrip]

    var body: some View {
        NavigationStack {
            Group {
                if observations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            summaryRow
                            classBreakdownChart
                            observationsPerMonthChart
                            topLocationsChart
                            liferTimeline
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 12) {
            FieldSummaryTile(value: "\(totalSpecies)", label: "Species", icon: "leaf.fill")
            FieldSummaryTile(value: "\(liferCount)", label: "Lifers", icon: "star.fill")
            FieldSummaryTile(value: "\(trips.count)", label: "Trips", icon: "map.fill")
        }
    }

    // MARK: - Class Breakdown

    private var classBreakdownChart: some View {
        FieldChartCard(title: "By Class") {
            HStack(spacing: 16) {
                Chart(classData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.speciesClass.color)
                    .cornerRadius(4)
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(classData) { item in
                        HStack(spacing: 6) {
                            Text(item.speciesClass.emoji).font(.caption).accessibilityHidden(true)
                            Text(item.speciesClass.rawValue).font(.caption)
                            Spacer()
                            Text("\(item.count)").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Per Month

    private var observationsPerMonthChart: some View {
        FieldChartCard(title: "Sightings per Month") {
            Chart(monthlyData) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("Sightings", item.count)
                )
                .foregroundStyle(FieldTheme.fern)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: - Top Locations

    private var topLocationsChart: some View {
        FieldChartCard(title: "Top Locations") {
            Chart(topLocations) { item in
                BarMark(
                    x: .value("Sightings", item.count),
                    y: .value("Location", item.name)
                )
                .foregroundStyle(FieldTheme.fern)
                .cornerRadius(4)
            }
            .frame(height: CGFloat(max(80, topLocations.count * 38)))
        }
    }

    // MARK: - Lifer Timeline

    private var liferTimeline: some View {
        FieldChartCard(title: "Life List (\(liferCount) species)") {
            Chart(lifersByMonth) { item in
                BarMark(
                    x: .value("Month", item.date, unit: .month),
                    y: .value("New lifers", item.count)
                )
                .foregroundStyle(Color.yellow)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 120)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 56))
                .foregroundStyle(FieldTheme.fern.opacity(0.5))
                .accessibilityHidden(true)
            Text("No insights yet")
                .font(.title3.bold())
            Text("Log observations to see your nature data here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No insights yet. Log observations to see data.")
    }

    // MARK: - Computed

    private var totalSpecies: Int {
        Set(observations.map { $0.speciesName.lowercased() }).count
    }

    private var liferCount: Int { observations.filter { $0.isLifer }.count }

    private struct ClassItem: Identifiable {
        let id = UUID(); let speciesClass: SpeciesClass; let count: Int
    }
    private struct MonthItem: Identifiable {
        let id = UUID(); let date: Date; let count: Int
    }
    private struct LocationItem: Identifiable {
        let id = UUID(); let name: String; let count: Int
    }

    private var classData: [ClassItem] {
        var counts: [SpeciesClass: Int] = [:]
        for o in observations { counts[o.speciesClass, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.map { ClassItem(speciesClass: $0.key, count: $0.value) }
    }

    private var monthlyData: [MonthItem] {
        let cal = Calendar.current
        var counts: [Date: Int] = [:]
        for o in observations {
            let start = cal.startOfMonth(for: o.date)
            counts[start, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.map { MonthItem(date: $0.key, count: $0.value) }
    }

    private var topLocations: [LocationItem] {
        var counts: [String: Int] = [:]
        for o in observations where !o.locationName.isEmpty {
            counts[o.locationName, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(6).map { LocationItem(name: $0.key, count: $0.value) }
    }

    private var lifersByMonth: [MonthItem] {
        let cal = Calendar.current
        var counts: [Date: Int] = [:]
        for o in observations where o.isLifer {
            let start = cal.startOfMonth(for: o.date)
            counts[start, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.map { MonthItem(date: $0.key, count: $0.value) }
    }
}

struct FieldSummaryTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(FieldTheme.fern).accessibilityHidden(true)
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct FieldChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 2)
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
