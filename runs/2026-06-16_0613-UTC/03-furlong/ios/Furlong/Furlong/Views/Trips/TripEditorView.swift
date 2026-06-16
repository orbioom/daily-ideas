import SwiftUI
import SwiftData

struct TripEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query private var vehicles: [Vehicle]
    @Query(sort: \FavoritePlace.name) private var favorites: [FavoritePlace]
    @Query(sort: \Trip.date, order: .reverse) private var allTrips: [Trip]

    let trip: Trip?
    let onSave: () -> Void

    enum DistanceMode: String, CaseIterable, Identifiable {
        case direct = "Enter distance"
        case odometer = "Odometer"
        var id: String { rawValue }
    }

    @State private var date = Date()
    @State private var purpose: TripPurpose = .business
    @State private var fromLabel = ""
    @State private var toLabel = ""
    @State private var roundTrip = false
    @State private var notes = ""
    @State private var selectedVehicle: Vehicle?

    @State private var distanceMode: DistanceMode = .direct
    @State private var distanceText = ""
    @State private var startOdoText = ""
    @State private var endOdoText = ""

    @State private var saveError: String?
    private let isEditing: Bool

    init(trip: Trip?, onSave: @escaping () -> Void) {
        self.trip = trip
        self.onSave = onSave
        self.isEditing = trip != nil
    }

    // Parsed, canonical one-way miles from whichever input mode is active.
    private var parsedMiles: Double? {
        switch distanceMode {
        case .direct:
            guard let v = Double(distanceText.replacingOccurrences(of: ",", with: ".")),
                  v >= 0 else { return nil }
            return settings.distanceUnit.toMiles(v)
        case .odometer:
            guard let start = Double(startOdoText.replacingOccurrences(of: ",", with: ".")),
                  let end = Double(endOdoText.replacingOccurrences(of: ",", with: ".")),
                  end >= start else { return nil }
            return settings.distanceUnit.toMiles(end - start)
        }
    }

    private var canSave: Bool {
        guard let miles = parsedMiles else { return false }
        return miles > 0
    }

    /// Place suggestions from favorites + recent trip labels.
    private var placeSuggestions: [String] {
        var set = Set<String>()
        favorites.forEach { set.insert($0.name) }
        for t in allTrips.prefix(40) {
            if !t.fromLabel.isEmpty { set.insert(t.fromLabel) }
            if !t.toLabel.isEmpty { set.insert(t.toLabel) }
        }
        return set.sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                purposeSection
                distanceSection
                routeSection
                detailsSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Trip" : "Log Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadInitial)
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private var purposeSection: some View {
        Section("Purpose") {
            Picker("Purpose", selection: $purpose) {
                ForEach(TripPurpose.allCases) { p in
                    Label(p.rawValue, systemImage: p.symbol).tag(p)
                }
            }
            .pickerStyle(.menu)
            DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
        }
        .listRowBackground(Theme.surface)
    }

    private var distanceSection: some View {
        Section {
            Picker("Mode", selection: $distanceMode) {
                ForEach(DistanceMode.allCases) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)

            if distanceMode == .direct {
                HStack {
                    Text("Distance (\(settings.distanceUnit.shortLabel))")
                    Spacer()
                    TextField("0.0", text: $distanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(Theme.mono(16, .semibold))
                        .frame(maxWidth: 120)
                }
            } else {
                HStack {
                    Text("Start odometer")
                    Spacer()
                    TextField("0", text: $startOdoText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(Theme.mono(16, .semibold))
                        .frame(maxWidth: 120)
                }
                HStack {
                    Text("End odometer")
                    Spacer()
                    TextField("0", text: $endOdoText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(Theme.mono(16, .semibold))
                        .frame(maxWidth: 120)
                }
            }

            Toggle("Round trip (doubles distance)", isOn: $roundTrip)
                .tint(Theme.accent)

            if let miles = parsedMiles {
                let effective = roundTrip ? miles * 2 : miles
                HStack {
                    Text("Counted distance")
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(settings.distance(effective))
                        .font(Theme.mono(16, .bold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("Enter a valid distance to continue.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.warn)
            }
        } header: {
            Text("Distance")
        } footer: {
            Text("Stored canonically in miles; shown in your chosen unit. Odometer mode derives distance from the difference.")
        }
        .listRowBackground(Theme.surface)
    }

    private var routeSection: some View {
        Section("Route") {
            placeField(title: "From", text: $fromLabel)
            placeField(title: "To", text: $toLabel)
            if !placeSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(favorites) { place in
                            Button {
                                applyFavorite(place)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill").font(.system(size: 9))
                                    Text(place.name)
                                }
                                .font(Theme.rounded(12, .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.accentSoft, in: Capsule())
                                .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityLabel("Favorite places. Tap to fill destination and distance.")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private func placeField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: text)
            let matches = suggestions(for: text.wrappedValue)
            if !matches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(matches, id: \.self) { s in
                            Button(s) { text.wrappedValue = s }
                                .font(Theme.rounded(12))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Theme.surfaceAlt, in: Capsule())
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
            }
        }
    }

    private func suggestions(for query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return placeSuggestions
            .filter { $0.lowercased().contains(q) && $0.lowercased() != q }
            .prefix(5)
            .map { $0 }
    }

    private var detailsSection: some View {
        Section("Details") {
            if vehicles.isEmpty {
                Text("No vehicles yet — add one in Settings › Vehicles.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Picker("Vehicle", selection: $selectedVehicle) {
                    Text("None").tag(Vehicle?.none)
                    ForEach(vehicles) { v in
                        Text(v.name).tag(Vehicle?.some(v))
                    }
                }
            }
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(1...4)
        }
        .listRowBackground(Theme.surface)
    }

    // MARK: - Actions

    private func applyFavorite(_ place: FavoritePlace) {
        toLabel = place.name
        roundTrip = settings.defaultRoundTrip ? true : roundTrip
        distanceMode = .direct
        let display = settings.distanceUnit.fromMiles(place.defaultMiles)
        distanceText = String(format: "%.1f", display)
        Haptics.selection(settings.hapticsEnabled)
    }

    private func loadInitial() {
        if let trip {
            date = trip.date
            purpose = trip.purpose
            fromLabel = trip.fromLabel
            toLabel = trip.toLabel
            roundTrip = trip.roundTrip
            notes = trip.notes
            selectedVehicle = trip.vehicle
            if let s = trip.startOdometer, let e = trip.endOdometer {
                distanceMode = .odometer
                startOdoText = NumberFormatting.odometer(s)
                endOdoText = NumberFormatting.odometer(e)
            } else {
                distanceMode = .direct
                let display = settings.distanceUnit.fromMiles(trip.miles)
                distanceText = String(format: "%.1f", display)
            }
        } else {
            purpose = settings.defaultPurpose
            roundTrip = settings.defaultRoundTrip
            selectedVehicle = vehicles.first { $0.isDefault } ?? vehicles.first
        }
    }

    private func save() {
        guard let miles = parsedMiles, miles > 0 else {
            saveError = "Please enter a valid distance greater than zero."
            return
        }
        let target = trip ?? Trip()
        target.date = date
        target.purpose = purpose
        target.miles = miles
        target.fromLabel = fromLabel.trimmingCharacters(in: .whitespaces)
        target.toLabel = toLabel.trimmingCharacters(in: .whitespaces)
        target.roundTrip = roundTrip
        target.notes = notes.trimmingCharacters(in: .whitespaces)
        target.vehicle = selectedVehicle

        if distanceMode == .odometer,
           let start = Double(startOdoText.replacingOccurrences(of: ",", with: ".")),
           let end = Double(endOdoText.replacingOccurrences(of: ",", with: ".")) {
            target.startOdometer = start
            target.endOdometer = end
        } else {
            target.startOdometer = nil
            target.endOdometer = nil
        }

        if trip == nil { context.insert(target) }
        do {
            try context.save()
            Haptics.success(settings.hapticsEnabled)
            onSave()
            dismiss()
        } catch {
            saveError = "Something went wrong saving this trip. Please try again."
        }
    }
}
