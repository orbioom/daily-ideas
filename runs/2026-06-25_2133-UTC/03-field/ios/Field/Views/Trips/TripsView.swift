import SwiftUI
import SwiftData

struct TripsView: View {
    @Query(sort: \FieldTrip.date, order: .reverse) private var trips: [FieldTrip]
    @Query(sort: \Observation.date, order: .reverse) private var observations: [Observation]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var editTrip: FieldTrip?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripList
                }
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(FieldTheme.fern)
                    }
                    .accessibilityLabel("Add trip")
                }
            }
            .sheet(isPresented: $showingAdd) { TripFormView(trip: nil) }
            .sheet(item: $editTrip) { trip in TripFormView(trip: trip) }
        }
    }

    private var tripList: some View {
        List {
            ForEach(trips) { trip in
                TripRowView(trip: trip, obsCount: observationCount(for: trip))
                    .onTapGesture { editTrip = trip }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(trip); try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 56))
                .foregroundStyle(FieldTheme.fern.opacity(0.5))
                .accessibilityHidden(true)
            Text("No trips yet")
                .font(.title3.bold())
            Text("Log a field trip to group observations and track your outings.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func observationCount(for trip: FieldTrip) -> Int {
        observations.filter { $0.tripName == trip.name }.count
    }
}

struct TripRowView: View {
    let trip: FieldTrip
    let obsCount: Int

    private static let df: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(FieldTheme.fern.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: trip.habitatType.sfSymbol)
                    .foregroundStyle(FieldTheme.fern)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.name.isEmpty ? "Unnamed trip" : trip.name)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(Self.df.string(from: trip.date)).font(.caption).foregroundStyle(.secondary)
                    if !trip.locationName.isEmpty {
                        Text("·").foregroundStyle(.secondary)
                        Text(trip.locationName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(trip.durationFormatted).font(.caption).foregroundStyle(.secondary)
                if obsCount > 0 {
                    Label("\(obsCount)", systemImage: "binoculars.fill")
                        .font(.caption.bold())
                        .foregroundStyle(FieldTheme.fern)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(Self.df.string(from: trip.date)), \(obsCount) sightings")
    }
}

struct TripFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let trip: FieldTrip?

    @State private var name: String
    @State private var date: Date
    @State private var locationName: String
    @State private var habitatType: HabitatType
    @State private var durationMinutes: Int
    @State private var distanceKm: Double
    @State private var weather: WeatherConditions
    @State private var notes: String

    init(trip: FieldTrip?) {
        self.trip = trip
        _name = State(initialValue: trip?.name ?? "")
        _date = State(initialValue: trip?.date ?? .now)
        _locationName = State(initialValue: trip?.locationName ?? "")
        _habitatType = State(initialValue: trip?.habitatType ?? .forest)
        _durationMinutes = State(initialValue: trip?.durationMinutes ?? 120)
        _distanceKm = State(initialValue: trip?.distanceKm ?? 0.0)
        _weather = State(initialValue: trip?.weather ?? .sunny)
        _notes = State(initialValue: trip?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trip") {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    HStack {
                        Text("Location")
                        Spacer()
                        TextField("Where", text: $locationName)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Habitat", selection: $habitatType) {
                        ForEach(HabitatType.allCases) { h in
                            Label(h.rawValue, systemImage: h.sfSymbol).tag(h)
                        }
                    }
                }
                Section("Details") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(durationMinutes)).foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(durationMinutes) },
                            set: { durationMinutes = Int($0) }
                        ), in: 15...600, step: 15)
                        .tint(FieldTheme.fern)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Distance (km)")
                            Spacer()
                            Text(String(format: "%.1f km", distanceKm)).foregroundStyle(.secondary)
                        }
                        Slider(value: $distanceKm, in: 0...50, step: 0.5).tint(FieldTheme.fern)
                    }
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherConditions.allCases) { w in
                            Label(w.rawValue, systemImage: w.sfSymbol).tag(w)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle(trip == nil ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(FieldTheme.fern)
                }
            }
        }
    }

    private func formatDuration(_ m: Int) -> String {
        let h = m / 60; let mn = m % 60
        if h > 0 && mn > 0 { return "\(h)h \(mn)m" }
        if h > 0 { return "\(h)h" }
        return "\(mn)m"
    }

    private func save() {
        if let t = trip {
            t.name = name; t.date = date; t.locationName = locationName
            t.habitatType = habitatType; t.durationMinutes = durationMinutes
            t.distanceKm = distanceKm; t.weather = weather; t.notes = notes
        } else {
            let t = FieldTrip(name: name, date: date, locationName: locationName,
                habitatType: habitatType, durationMinutes: durationMinutes,
                distanceKm: distanceKm, weather: weather, notes: notes)
            context.insert(t)
        }
        try? context.save()
        dismiss()
    }
}
