import SwiftUI
import SwiftData

struct TripsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.startDate, order: .forward) private var trips: [Trip]

    @AppStorage("defaultCurrency") private var defaultCurrency = Locale.current.currency?.identifier ?? "USD"
    @State private var showSettings = false
    @State private var editingTrip: Trip?

    private let engine = TripEngine()
    private let calendar = Calendar.current

    private var upcoming: [Trip] {
        trips.filter {
            if case .past = engine.status($0) { return false }
            return true
        }
    }
    private var past: [Trip] {
        trips.filter {
            if case .past = engine.status($0) { return true }
            return false
        }.sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if trips.isEmpty {
                    EmptyStateView(
                        icon: "airplane.departure",
                        title: "No trips yet",
                        message: "Tap + to plan your first trip. Add days, stays, packing, and a budget — all on your device."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if !upcoming.isEmpty {
                                sectionHeader("Upcoming")
                                ForEach(upcoming) { trip in tripCardLink(trip) }
                            }
                            if !past.isEmpty {
                                sectionHeader("Past")
                                ForEach(past) { trip in tripCardLink(trip) }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trips")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        editingTrip = makeNewTrip()
                    } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New trip")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $editingTrip) { trip in
                TripEditorView(trip: trip, isNew: trip.activities.isEmpty && trip.name.isEmpty)
            }
        }
    }

    private func makeNewTrip() -> Trip {
        let start = calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: .now)) ?? .now
        let end = calendar.date(byAdding: .day, value: 17, to: calendar.startOfDay(for: .now)) ?? .now
        let trip = Trip(name: "", startDate: start, endDate: end, currencyCode: defaultCurrency)
        context.insert(trip)
        return trip
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Eyebrow(text: title)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func tripCardLink(_ trip: Trip) -> some View {
        NavigationLink(value: trip) {
            TripCard(trip: trip, engine: engine)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { editingTrip = trip } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) {
                context.delete(trip); Haptics.warning()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    let engine: TripEngine

    var body: some View {
        let status = engine.status(trip)
        let gaps = engine.nightsWithoutLodging(trip)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(Color(hex: trip.colorHex)).frame(width: 10, height: 10)
                Text(trip.name.isEmpty ? "Untitled trip" : trip.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Spacer()
                statusBadge(status)
            }
            if !trip.destination.isEmpty {
                Label(trip.destination, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar").font(.caption).foregroundStyle(Brand.text3)
                Text(dateRange)
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            HStack(spacing: 16) {
                metric(icon: "list.bullet", "\(trip.activities.count)", "plans")
                metric(icon: "bed.double", "\(engine.dayCount(trip))", "days")
                if gaps > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2).foregroundStyle(Brand.warn)
                        Text("\(gaps) \(gaps == 1 ? "night" : "nights") unbooked")
                            .font(.caption).foregroundStyle(Brand.warn)
                    }
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(status.label), \(dateRange)")
    }

    private var dateRange: String {
        "\(Format.shortDate.string(from: trip.startDate)) – \(Format.shortDate.string(from: trip.endDate))"
    }

    private func metric(icon: String, _ value: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(Brand.text3)
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
            Text(label).font(.caption).foregroundStyle(Brand.text3)
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: TripStatus) -> some View {
        let isActive: Bool = { if case .active = status { return true }; return false }()
        Text(status.label)
            .font(Brand.mono(11, weight: .medium))
            .foregroundStyle(isActive ? Brand.live : Brand.text2)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background((isActive ? Brand.live : Brand.text3).opacity(0.14), in: Capsule())
    }
}
