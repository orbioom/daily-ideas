import SwiftUI
import SwiftData

struct TripsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CampTrip.startDate, order: .reverse) private var trips: [CampTrip]
    @State private var showAdd = false
    @State private var filter: TripStatus?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()

    var filtered: [CampTrip] {
        guard let f = filter else { return trips }
        return trips.filter { $0.status == f }
    }

    var upcoming: [CampTrip] { filtered.filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate } }
    var past: [CampTrip] { filtered.filter { $0.startDate <= Date() }.sorted { $0.startDate > $1.startDate } }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    List {
                        filterRow
                        if !upcoming.isEmpty {
                            Section("Upcoming") {
                                ForEach(upcoming) { trip in
                                    NavigationLink(value: trip) {
                                        TripRowView(trip: trip)
                                    }
                                }
                                .onDelete { idx in delete(upcoming, at: idx) }
                            }
                        }
                        if !past.isEmpty {
                            Section("Past Trips") {
                                ForEach(past) { trip in
                                    NavigationLink(value: trip) {
                                        TripRowView(trip: trip)
                                    }
                                }
                                .onDelete { idx in delete(past, at: idx) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: CampTrip.self) { TripDetailView(trip: $0) }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Add trip")
                }
            }
            .sheet(isPresented: $showAdd) { AddEditTripView(trip: nil) }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: filter == nil) { filter = nil }
                ForEach(TripStatus.allCases, id: \.self) { s in
                    filterChip(s.rawValue, selected: filter == s) { filter = filter == s ? nil : s }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(selected ? CampfireTheme.accent : CampfireTheme.secondary))
                .foregroundColor(selected ? .white : CampfireTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("⛺️").font(.system(size: 64)).accessibilityHidden(true)
            Text("No Trips Yet").font(.title2.bold())
            Text("Plan your first camping adventure!").foregroundColor(CampfireTheme.secondaryLabel)
            Button("Add First Trip") { showAdd = true }.buttonStyle(.borderedProminent)
                .accessibilityLabel("Add first trip")
        }
        .padding()
    }

    private func delete(_ list: [CampTrip], at offsets: IndexSet) {
        for i in offsets { context.delete(list[i]) }
        try? context.save()
    }
}

struct TripRowView: View {
    let trip: CampTrip
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "MMM d"; return f }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(CampfireTheme.label)
                Spacer()
                Text(trip.status.rawValue)
                    .font(.caption)
                    .foregroundColor(CampfireTheme.statusColor(trip.status))
            }
            Text("\(trip.campType.rawValue) · \(Self.fmt.string(from: trip.startDate))–\(Self.fmt.string(from: trip.endDate))")
                .font(.caption)
                .foregroundColor(CampfireTheme.secondaryLabel)

            if !trip.gearItems.isEmpty {
                ProgressView(value: trip.gearProgress)
                    .tint(CampfireTheme.forest)
                    .accessibilityLabel("Gear packed: \(Int(trip.gearProgress*100))%")
            }

            if let days = trip.daysUntil {
                Text("In \(days) day\(days == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .foregroundColor(CampfireTheme.accent)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(trip.campType.rawValue)")
    }
}
