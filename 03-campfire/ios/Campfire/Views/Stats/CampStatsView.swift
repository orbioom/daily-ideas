import SwiftUI
import SwiftData
import Charts

struct CampStatsView: View {
    @Query private var trips: [CampTrip]

    private var completedTrips: [CampTrip] { trips.filter { $0.status == .completed } }
    private var totalNights: Int { completedTrips.reduce(0) { $0 + $1.duration } }
    private var totalGearItems: Int { trips.reduce(0) { $0 + $1.gearItems.count } }
    private var totalNatureLogs: Int { trips.reduce(0) { $0 + $1.natureLogs.count } }
    private var avgRating: Double {
        let rated = completedTrips.filter { $0.rating > 0 }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0) { $0 + $1.rating }) / Double(rated.count)
    }

    private var tripsByYear: [(String, Int)] {
        var d: [String: Int] = [:]
        let cal = Calendar.current
        for t in completedTrips {
            let yr = String(cal.component(.year, from: t.startDate))
            d[yr, default: 0] += 1
        }
        return d.sorted { $0.key < $1.key }
    }

    private var campTypeBreakdown: [(String, Int)] {
        var d: [String: Int] = [:]
        for t in trips { d[t.campType.rawValue, default: 0] += 1 }
        return d.sorted { $0.value > $1.value }
    }

    private var natureCategoryBreakdown: [(String, Int)] {
        var d: [String: Int] = [:]
        for t in trips {
            for log in t.natureLogs { d[log.category.rawValue, default: 0] += 1 }
        }
        return d.sorted { $0.value > $1.value }
    }

    var body: some View {
        NavigationStack {
            List {
                if trips.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Text("⛺️").font(.system(size: 48)).accessibilityHidden(true)
                            Text("No trips yet")
                                .font(.headline)
                                .foregroundColor(CampfireTheme.secondaryLabel)
                            Text("Add your first camping trip to see stats here.")
                                .font(.caption)
                                .foregroundColor(CampfireTheme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    Section("Overview") {
                        statRow("Trips Completed", value: "\(completedTrips.count)")
                        statRow("Total Nights Out", value: "\(totalNights)")
                        statRow("Gear Items Tracked", value: "\(totalGearItems)")
                        statRow("Nature Sightings", value: "\(totalNatureLogs)")
                        if avgRating > 0 {
                            statRow("Avg Trip Rating", value: String(format: "%.1f ★", avgRating))
                        }
                    }

                    if !tripsByYear.isEmpty {
                        Section("Trips by Year") {
                            Chart(tripsByYear, id: \.0) { yr, count in
                                BarMark(
                                    x: .value("Year", yr),
                                    y: .value("Trips", count)
                                )
                                .foregroundStyle(CampfireTheme.accent)
                            }
                            .frame(height: 140)
                            .padding(.vertical, 8)
                            .accessibilityLabel("Bar chart of trips by year")
                        }
                    }

                    if !campTypeBreakdown.isEmpty {
                        Section("Camp Style") {
                            ForEach(campTypeBreakdown, id: \.0) { name, count in
                                HStack {
                                    Text(name).foregroundColor(CampfireTheme.label)
                                    Spacer()
                                    Text("\(count)").foregroundColor(CampfireTheme.secondaryLabel)
                                }
                                .accessibilityLabel("\(name): \(count) trip\(count == 1 ? "" : "s")")
                            }
                        }
                    }

                    if !natureCategoryBreakdown.isEmpty {
                        Section("Nature Sightings") {
                            Chart(natureCategoryBreakdown, id: \.0) { name, count in
                                BarMark(
                                    x: .value("Count", count),
                                    y: .value("Category", name)
                                )
                                .foregroundStyle(CampfireTheme.forest)
                            }
                            .frame(height: CGFloat(natureCategoryBreakdown.count * 30 + 20))
                            .padding(.vertical, 8)
                            .accessibilityLabel("Bar chart of nature sightings by category")
                        }
                    }

                    if !completedTrips.isEmpty {
                        Section("Favorite Spots") {
                            let sites = topCampsites()
                            if sites.isEmpty {
                                Text("No campsites named yet")
                                    .foregroundColor(CampfireTheme.secondaryLabel)
                                    .font(.caption)
                            } else {
                                ForEach(sites, id: \.0) { site, count in
                                    HStack {
                                        Label(site, systemImage: "mappin.circle.fill")
                                            .foregroundColor(CampfireTheme.accent)
                                        Spacer()
                                        Text("\(count)x").foregroundColor(CampfireTheme.secondaryLabel)
                                    }
                                    .accessibilityLabel("\(site), visited \(count) time\(count == 1 ? "" : "s")")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(CampfireTheme.label)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(CampfireTheme.accent)
        }
        .accessibilityLabel("\(label): \(value)")
    }

    private func topCampsites() -> [(String, Int)] {
        var d: [String: Int] = [:]
        for t in completedTrips where !t.campsite.isEmpty {
            d[t.campsite, default: 0] += 1
        }
        return d.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
}
