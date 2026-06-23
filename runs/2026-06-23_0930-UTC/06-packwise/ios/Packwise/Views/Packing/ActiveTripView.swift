import SwiftUI
import SwiftData

/// The Packing tab. Shows the user's active trip detail, or a chooser when
/// none is selected.
struct ActiveTripView: View {
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @AppStorage("activeTripID") private var activeTripID: String = ""

    private var activeTrip: Trip? {
        trips.first { $0.id.uuidString == activeTripID }
    }

    private var suggestedTrips: [Trip] {
        trips.filter { !$0.isPast }.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let trip = activeTrip {
                    TripDetailView(trip: trip)
                } else if trips.isEmpty {
                    EmptyStateView(
                        symbol: "checklist",
                        title: "Nothing to pack yet",
                        message: "Plan a trip from the Trips tab and it'll appear here ready to pack."
                    )
                    .background(Theme.background)
                    .navigationTitle("Packing")
                } else {
                    chooser
                }
            }
        }
    }

    private var chooser: some View {
        ScrollView {
            VStack(spacing: Theme.Space.lg) {
                EmptyStateView(
                    symbol: "hand.tap.fill",
                    title: "Pick a trip to pack",
                    message: "Choose which trip to focus on. It stays here until you switch."
                )
                ForEach(suggestedTrips.isEmpty ? trips : suggestedTrips) { trip in
                    Button {
                        activeTripID = trip.id.uuidString
                    } label: {
                        TripCard(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle("Packing")
    }
}
