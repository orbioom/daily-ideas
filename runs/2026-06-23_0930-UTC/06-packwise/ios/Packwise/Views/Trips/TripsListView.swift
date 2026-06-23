import SwiftUI
import SwiftData

/// Screen 1 — all trips, split into upcoming and past, with create + delete.
struct TripsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate, order: .forward) private var trips: [Trip]
    @AppStorage("activeTripID") private var activeTripID: String = ""

    @State private var showingNewTrip = false
    @State private var tripToDelete: Trip?

    private var upcoming: [Trip] {
        trips.filter { !$0.isPast }.sorted { $0.startDate < $1.startDate }
    }
    private var past: [Trip] {
        trips.filter { $0.isPast }.sorted { $0.endDate > $1.endDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    EmptyStateView(
                        symbol: "suitcase.rolling.fill",
                        title: "No trips yet",
                        message: "Create your first trip and Packwise will generate a tailored packing list for you.",
                        actionTitle: "Plan a trip",
                        action: { showingNewTrip = true }
                    )
                } else {
                    tripList
                }
            }
            .background(Theme.background)
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Plan a new trip")
                }
            }
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $showingNewTrip) {
                TripFormFlow()
            }
            .confirmationDialog(
                "Delete this trip?",
                isPresented: Binding(
                    get: { tripToDelete != nil },
                    set: { if !$0 { tripToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete trip", role: .destructive) {
                    if let trip = tripToDelete { delete(trip) }
                    tripToDelete = nil
                }
                Button("Cancel", role: .cancel) { tripToDelete = nil }
            } message: {
                Text("This removes the trip and its packing list permanently.")
            }
        }
    }

    private var tripList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Space.lg, pinnedViews: []) {
                if !upcoming.isEmpty {
                    sectionHeader("Upcoming")
                    ForEach(upcoming) { trip in
                        NavigationLink(value: trip) {
                            TripCard(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { rowMenu(for: trip) }
                    }
                }
                if !past.isEmpty {
                    sectionHeader("Past")
                    ForEach(past) { trip in
                        NavigationLink(value: trip) {
                            TripCard(trip: trip)
                                .opacity(0.7)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { rowMenu(for: trip) }
                    }
                }
            }
            .padding(Theme.Space.lg)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(.top, Theme.Space.xs)
    }

    @ViewBuilder
    private func rowMenu(for trip: Trip) -> some View {
        Button {
            activeTripID = trip.id.uuidString
        } label: {
            Label("Set as active", systemImage: "checklist")
        }
        Button(role: .destructive) {
            tripToDelete = trip
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func delete(_ trip: Trip) {
        if activeTripID == trip.id.uuidString {
            activeTripID = ""
        }
        context.delete(trip)
        try? context.save()
    }
}
