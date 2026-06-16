import SwiftUI
import SwiftData

/// Pick an observing location from the bundled gazetteer, saved locations,
/// or enter manual coordinates. No location permission required.
struct LocationsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLocation.createdAt) private var saved: [SavedLocation]

    @State private var query = ""
    @State private var showManual = false

    /// Free tier sees a curated subset of cities; Pro unlocks all.
    private let freeCityIDs: Set<String> = [
        "city.london", "city.newyork", "city.losangeles", "city.chicago",
        "city.tokyo", "city.sydney", "city.paris", "city.berlin",
        "city.delhi", "city.capetown", "city.saopaulo", "city.dubai"
    ]

    private var availableCities: [GazetteerCity] {
        let base = isPro ? Gazetteer.cities : Gazetteer.cities.filter { freeCityIDs.contains($0.id) }
        guard !query.isEmpty else { return base }
        let q = query.lowercased()
        return base.filter { $0.name.lowercased().contains(q) || $0.country.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                List {
                    if !saved.isEmpty {
                        Section("Saved") {
                            ForEach(saved) { loc in
                                row(id: loc.locationID, title: loc.name,
                                    subtitle: Fmt.coord(lat: loc.latitude, lon: loc.longitude))
                            }
                            .onDelete(perform: deleteSaved)
                        }
                    }

                    Section {
                        Button {
                            showManual = true
                        } label: {
                            Label("Enter coordinates manually", systemImage: "scope")
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    Section(isPro ? "All cities" : "Cities") {
                        ForEach(availableCities) { city in
                            row(id: city.id, title: city.displayName,
                                subtitle: Fmt.coord(lat: city.latitude, lon: city.longitude),
                                onSelect: { ensureSaved(city) })
                        }
                    }

                    if !isPro {
                        Section {
                            NavigationLink {
                                PaywallView()
                            } label: {
                                Label("Unlock all \(Gazetteer.cities.count) cities with Pro", systemImage: "globe")
                                    .foregroundStyle(Theme.gold)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search cities")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showManual) {
                ManualLocationSheet()
            }
        }
    }

    private func row(id: String, title: String, subtitle: String, onSelect: (() -> Void)? = nil) -> some View {
        Button {
            onSelect?()
            settings.selectedLocationID = id
            Haptics.selection(settings.hapticsEnabled)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.rounded(16, .medium)).foregroundStyle(Theme.ink)
                    Text(subtitle).font(.caption).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if settings.selectedLocationID == id {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                }
            }
        }
        .listRowBackground(Theme.surface)
        .accessibilityLabel("\(title). \(subtitle)\(settings.selectedLocationID == id ? ". Selected" : "")")
    }

    /// Persist a chosen gazetteer city as a SavedLocation (so it appears under Saved).
    private func ensureSaved(_ city: GazetteerCity) {
        if !saved.contains(where: { $0.locationID == city.id }) {
            modelContext.insert(SavedLocation(locationID: city.id, name: city.displayName,
                                              latitude: city.latitude, longitude: city.longitude,
                                              timeZoneID: city.timeZoneID))
            try? modelContext.save()
        }
    }

    private func deleteSaved(_ offsets: IndexSet) {
        for i in offsets {
            guard saved.indices.contains(i) else { continue }
            modelContext.delete(saved[i])
        }
        try? modelContext.save()
    }
}

/// Sheet for entering custom latitude / longitude.
private struct ManualLocationSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latText = ""
    @State private var lonText = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Home, Dark-sky site", text: $name)
                }
                Section("Coordinates") {
                    TextField("Latitude (−90 to 90)", text: $latText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude (−180 to 180, east +)", text: $lonText)
                        .keyboardType(.numbersAndPunctuation)
                }
                if let error {
                    Section { Text(error).font(.footnote).foregroundStyle(Theme.bad) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Manual location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") { apply() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                latText = String(format: "%.4f", settings.manualLatitude)
                lonText = String(format: "%.4f", settings.manualLongitude)
                name = settings.manualLocationName
            }
        }
    }

    private func apply() {
        guard let lat = Double(latText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(lonText.trimmingCharacters(in: .whitespaces)) else {
            error = "Please enter numeric coordinates."
            return
        }
        guard lat >= -90, lat <= 90 else { error = "Latitude must be between −90 and 90."; return }
        guard lon >= -180, lon <= 180 else { error = "Longitude must be between −180 and 180."; return }
        settings.manualLatitude = lat
        settings.manualLongitude = lon
        settings.manualLocationName = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Custom location" : name
        settings.selectedLocationID = "manual"
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
