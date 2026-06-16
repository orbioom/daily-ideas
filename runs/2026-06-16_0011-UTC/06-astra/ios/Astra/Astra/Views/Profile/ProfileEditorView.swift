import SwiftUI
import SwiftData

/// Add or edit a birth chart. Supports the gazetteer city picker or manual lat/long,
/// the "exact time unknown" toggle, and setting the primary chart.
struct ProfileEditorView: View {
    /// nil = creating a new profile.
    let profile: Profile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allProfiles: [Profile]

    @State private var name = ""
    @State private var birthDate = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 15, hour: 12, minute: 0)) ?? Date()
    @State private var hasExactTime = true
    @State private var useManualCoords = false
    @State private var cityID = CityGazetteer.defaultCityID
    @State private var manualLat = "51.5074"
    @State private var manualLong = "-0.1278"
    @State private var manualOffset = "0"
    @State private var makePrimary = false
    @State private var citySearch = ""
    @State private var showPaywall = false

    private var isEditing: Bool { profile != nil }

    private var selectedCity: GazetteerCity? {
        CityGazetteer.city(id: cityID)
    }

    private var filteredCities: [GazetteerCity] {
        CityGazetteer.search(citySearch)
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                birthSection
                locationSection
                primarySection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit chart" : "New chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .moreProfiles)
            }
            .onAppear(perform: load)
        }
    }

    private var identitySection: some View {
        Section("Who") {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
        }
    }

    private var birthSection: some View {
        Section("Born") {
            DatePicker("Birth date", selection: $birthDate,
                       displayedComponents: hasExactTime ? [.date, .hourAndMinute] : [.date])
            Toggle("I know the exact time", isOn: $hasExactTime)
            if !hasExactTime {
                Text("Without an exact time, Astra hides houses and your Rising sign — planet signs stay accurate.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var locationSection: some View {
        Section("Born in") {
            Toggle("Enter coordinates manually", isOn: $useManualCoords)
            if useManualCoords {
                TextField("Latitude (-90 to 90)", text: $manualLat)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Longitude (-180 to 180)", text: $manualLong)
                    .keyboardType(.numbersAndPunctuation)
                TextField("UTC offset in hours (e.g. -5)", text: $manualOffset)
                    .keyboardType(.numbersAndPunctuation)
                Text("Tip: a city captures the standard offset for you. Use manual entry for places not listed.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            } else {
                TextField("Search cities", text: $citySearch)
                    .autocorrectionDisabled()
                Picker("City", selection: $cityID) {
                    ForEach(filteredCities) { city in
                        Text(city.displayName).tag(city.id)
                    }
                }
                .pickerStyle(.navigationLink)
                if let city = selectedCity {
                    HStack {
                        Text("Offset")
                        Spacer()
                        Text("UTC\(city.tzOffset >= 0 ? "+" : "")\(formatOffset(city.tzOffset))")
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .font(Theme.rounded(13))
                }
            }
        }
    }

    private var primarySection: some View {
        Section {
            Toggle("Make this my primary chart", isOn: $makePrimary)
        } footer: {
            Text("The primary chart drives the Today and Chart tabs.")
        }
    }

    private func formatOffset(_ offset: Double) -> String {
        if offset == floor(offset) {
            return String(format: "%.0f", offset)
        }
        return String(format: "%.1f", offset)
    }

    private func load() {
        guard let profile else {
            // New: default primary if this is the very first chart.
            makePrimary = allProfiles.isEmpty
            return
        }
        name = profile.name
        birthDate = profile.birthDate.addingTimeInterval(profile.tzOffsetHours * 3600) // show local birth time
        hasExactTime = profile.hasExactTime
        makePrimary = profile.isPrimary
        manualLat = String(profile.latitude)
        manualLong = String(profile.longitude)
        manualOffset = formatOffset(profile.tzOffsetHours)
        // Try to match a known city; otherwise fall back to manual.
        if let match = CityGazetteer.cities.first(where: {
            abs($0.latitude - profile.latitude) < 0.05 && abs($0.longitude - profile.longitude) < 0.05
        }) {
            cityID = match.id
            useManualCoords = false
        } else {
            useManualCoords = true
        }
    }

    private func save() {
        // Pro gate: free tier keeps a single chart.
        if !isEditing && !isPro && allProfiles.count >= Pro.freeProfileLimit {
            showPaywall = true
            return
        }

        let (lat, lon, offset, locName) = resolvedLocation()
        // Convert the entered LOCAL birth time to a UTC instant for the ephemeris.
        let utc = birthDate.addingTimeInterval(-offset * 3600)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let profile {
            profile.name = trimmedName
            profile.birthDate = utc
            profile.hasExactTime = hasExactTime
            profile.latitude = min(max(lat, -89.9), 89.9)
            profile.longitude = min(max(lon, -180), 180)
            profile.locationName = locName
            profile.tzOffsetHours = min(max(offset, -14), 14)
            applyPrimary(to: profile)
        } else {
            let newProfile = Profile(name: trimmedName,
                                     birthDate: utc,
                                     hasExactTime: hasExactTime,
                                     latitude: lat,
                                     longitude: lon,
                                     locationName: locName,
                                     tzOffsetHours: offset,
                                     isPrimary: makePrimary || allProfiles.isEmpty,
                                     colorSeed: allProfiles.count)
            modelContext.insert(newProfile)
            applyPrimary(to: newProfile)
        }

        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func resolvedLocation() -> (lat: Double, lon: Double, offset: Double, name: String) {
        if useManualCoords {
            let lat = Double(manualLat.trimmingCharacters(in: .whitespaces)) ?? 0
            let lon = Double(manualLong.trimmingCharacters(in: .whitespaces)) ?? 0
            let off = Double(manualOffset.trimmingCharacters(in: .whitespaces)) ?? 0
            let name = String(format: "%.2f, %.2f", lat, lon)
            return (lat, lon, off, name)
        } else if let city = selectedCity {
            return (city.latitude, city.longitude, city.tzOffset, city.displayName)
        } else {
            let fallback = CityGazetteer.cities[0]
            return (fallback.latitude, fallback.longitude, fallback.tzOffset, fallback.displayName)
        }
    }

    /// Ensure only one primary exists when this one is flagged.
    private func applyPrimary(to profile: Profile) {
        guard makePrimary else { return }
        for other in allProfiles where other.id != profile.id {
            other.isPrimary = false
        }
        profile.isPrimary = true
        settings.primaryProfileID = profile.id.uuidString
    }
}

#Preview {
    ProfileEditorView(profile: nil)
        .modelContainer(PreviewContainer.shared)
        .environmentObject(AppSettings())
}
