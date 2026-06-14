import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Trip.startDate, order: .forward) private var trips: [Trip]

    @State private var showingAdd = false
    @State private var paywallReason: PaywallReason?

    // Group trips by phase using the engine countdown.
    private var grouped: [(phase: TripPhase, trips: [Trip])] {
        var buckets: [TripPhase: [Trip]] = [:]
        for trip in trips {
            let c = ItineraryEngine.countdown(start: trip.startDate, end: trip.endDate)
            buckets[c.phase, default: []].append(trip)
        }
        let order: [TripPhase] = [.inProgress, .upcoming, .past]
        return order.compactMap { phase in
            guard let group = buckets[phase], !group.isEmpty else { return nil }
            let sorted: [Trip]
            switch phase {
            case .past:
                sorted = group.sorted { $0.startDate > $1.startDate }
            default:
                sorted = group.sorted { $0.startDate < $1.startDate }
            }
            return (phase, sorted)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    EmptyStateView(symbol: "airplane.departure",
                                   title: "No trips yet",
                                   message: "Plan your first jaunt — name it, pick the dates, and build a day-by-day itinerary.",
                                   actionTitle: "Plan a trip",
                                   action: attemptAdd)
                } else {
                    List {
                        ForEach(grouped, id: \.phase) { group in
                            Section {
                                ForEach(group.trips) { trip in
                                    ZStack {
                                        NavigationLink(value: trip) { EmptyView() }
                                            .opacity(0)
                                        TripCard(trip: trip, currencySymbol: settings.currencySymbol)
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete { offsets in delete(group.trips, at: offsets) }
                            } header: {
                                Text(group.phase.sectionTitle)
                                    .font(Theme.font(.subheadline, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Trips")
            .navigationDestination(for: Trip.self) { trip in
                TripOverviewView(trip: trip)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: attemptAdd) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Plan a trip")
                }
            }
            .sheet(isPresented: $showingAdd) {
                TripEditorView(trip: nil)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    private func attemptAdd() {
        if Pro.canCreateTrip(currentCount: trips.count, isPro: isPro) {
            Haptics.tap()
            showingAdd = true
        } else {
            Haptics.warning()
            paywallReason = .tripLimit
        }
    }

    private func delete(_ source: [Trip], at offsets: IndexSet) {
        Haptics.tap()
        for index in offsets where index < source.count {
            context.delete(source[index])
        }
    }
}

// MARK: - Trip card

struct TripCard: View {
    let trip: Trip
    let currencySymbol: String

    private var countdown: ItineraryEngine.Countdown {
        ItineraryEngine.countdown(start: trip.startDate, end: trip.endDate)
    }

    private var dateRange: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        let start = f.string(from: trip.startDate)
        let end = f.string(from: trip.endDate)
        return "\(start) – \(end)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Theme.coverGradient(hue: trip.coverHue)
                    .frame(height: 96)
                LinearGradient(colors: [.black.opacity(0.0), .black.opacity(0.35)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 96)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(Theme.font(.title3, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                        Text(trip.destination.isEmpty ? "Destination TBD" : trip.destination)
                            .font(Theme.font(.caption, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.92))
                }
                .padding(12)
            }
            HStack {
                Label(dateRange, systemImage: "calendar")
                    .font(Theme.font(.caption, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(ItineraryEngine.countdownLabel(countdown))
                    .font(Theme.font(.caption, weight: .bold))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(badgeColor.opacity(0.15)))
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(trip.name), \(trip.destination.isEmpty ? "destination to be decided" : trip.destination)")
        .accessibilityValue("\(dateRange), \(ItineraryEngine.countdownLabel(countdown))")
        .accessibilityHint("Opens trip overview")
    }

    private var badgeColor: Color {
        switch countdown.phase {
        case .inProgress: return Theme.success
        case .upcoming: return Theme.accent
        case .past: return Theme.textSecondary
        }
    }
}
