import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

    @State private var editingTrip: Trip?
    @State private var newTrip: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ScrollView {
                        VStack(spacing: 18) {
                            EmptyStateView(icon: "suitcase",
                                           title: "No trips yet",
                                           message: "Group countries into journeys with dates and notes — a Eurotrip, a honeymoon, a gap year.")
                            Button {
                                createTrip()
                            } label: {
                                Label("New trip", systemImage: "plus")
                            }
                            .buttonStyle(InkButtonStyle())
                        }
                        .glassCard()
                        .padding(20)
                    }
                } else {
                    List {
                        ForEach(trips) { trip in
                            Button {
                                Haptics.tap()
                                editingTrip = trip
                            } label: {
                                TripRow(trip: trip)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteTrips)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createTrip()
                    } label: {
                        Label("New trip", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingTrip) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(item: $newTrip) { trip in
                TripDetailView(trip: trip, isNew: true)
            }
        }
    }

    private func createTrip() {
        Haptics.tap()
        let trip = Trip(title: "")
        context.insert(trip)
        newTrip = trip
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets where trips.indices.contains(index) {
            context.delete(trips[index])
        }
        try? context.save()
        Haptics.warning()
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.title.isEmpty ? "Untitled trip" : trip.title)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer()
                if let range = trip.dateRangeLabel {
                    Text(range)
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                }
            }
            if trip.countries.isEmpty {
                Text("No countries yet")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
            } else {
                Text(flagLine)
                    .font(.system(size: 22))
                    .lineLimit(1)
                    .accessibilityHidden(true)
                Text("\(trip.countries.count) \(trip.countries.count == 1 ? "country" : "countries")")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var flagLine: String {
        trip.countries.prefix(12).map(\.flagEmoji).joined(separator: " ")
    }

    private var accessibilityText: String {
        var parts = [trip.title.isEmpty ? "Untitled trip" : trip.title]
        if let range = trip.dateRangeLabel { parts.append(range) }
        let names = trip.countries.map(\.name)
        if !names.isEmpty { parts.append(names.joined(separator: ", ")) }
        return parts.joined(separator: ". ")
    }
}
