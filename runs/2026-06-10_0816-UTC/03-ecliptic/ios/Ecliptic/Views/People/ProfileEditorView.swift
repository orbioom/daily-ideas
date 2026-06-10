import SwiftUI
import SwiftData

/// Create (profile == nil) or edit a birth profile. The DatePicker is shown
/// in the birth city's time zone so the entered wall time is interpreted
/// exactly where it happened.
struct ProfileEditorView: View {
    let profile: ChartProfile?
    var makePrimary: Bool = false
    var onSave: (() -> Void)? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allProfiles: [ChartProfile]

    @State private var name = ""
    @State private var city: City?
    @State private var birthDate = defaultBirthDate
    @State private var timeKnown = true
    @State private var showCityPicker = false
    @State private var error: String?
    @State private var loaded = false

    private static var defaultBirthDate: Date {
        Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 15, hour: 12)) ?? .now
    }

    private var timeZone: TimeZone {
        city.flatMap { TimeZone(identifier: $0.timeZoneID) } ?? .current
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who") {
                    TextField("Name", text: $name)
                }

                Section {
                    Button {
                        showCityPicker = true
                    } label: {
                        HStack {
                            Text("Birth place")
                                .foregroundStyle(Brand.text)
                            Spacer()
                            Text(city?.label ?? "Choose a city")
                                .foregroundStyle(city == nil ? Brand.text3 : Brand.text2)
                        }
                    }
                    .accessibilityHint("Opens the city picker")
                } footer: {
                    if let city {
                        Text("Times below are read in \(city.timeZoneID.replacingOccurrences(of: "_", with: " ")).")
                    }
                }

                Section("When") {
                    DatePicker("Date", selection: $birthDate, displayedComponents: .date)
                        .environment(\.timeZone, timeZone)
                    Toggle("I know the birth time", isOn: $timeKnown)
                        .tint(Brand.live)
                    if timeKnown {
                        DatePicker("Time", selection: $birthDate, displayedComponents: .hourAndMinute)
                            .environment(\.timeZone, timeZone)
                    } else {
                        Text("Without a time, Ecliptic uses noon and skips the rising sign and houses — planets stay exact.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }

                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle(profile == nil ? "New Chart" : "Edit Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerView { picked in
                    city = picked
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let p = profile {
                    name = p.name
                    birthDate = p.birthDate
                    timeKnown = p.timeKnown
                    city = CityCatalog.all.first {
                        abs($0.latitude - p.latitude) < 0.001 && abs($0.longitude - p.longitude) < 0.001
                    } ?? City(name: p.placeName, country: "", latitude: p.latitude,
                              longitude: p.longitude, timeZoneID: p.timeZoneID)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "A name helps you tell charts apart."
            return
        }
        guard let city else {
            error = "Pick the birth city — houses need a place on Earth."
            return
        }

        var saveDate = birthDate
        if !timeKnown {
            // Anchor to local noon in the birth zone for stable planet positions.
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = timeZone
            var comps = cal.dateComponents([.year, .month, .day], from: birthDate)
            comps.hour = 12
            comps.minute = 0
            saveDate = cal.date(from: comps) ?? birthDate
        }

        if let p = profile {
            p.name = trimmed
            p.birthDate = saveDate
            p.timeZoneID = city.timeZoneID
            p.latitude = city.latitude
            p.longitude = city.longitude
            p.placeName = city.label
            p.timeKnown = timeKnown
        } else {
            let p = ChartProfile(name: trimmed, birthDate: saveDate,
                                 timeZoneID: city.timeZoneID,
                                 latitude: city.latitude, longitude: city.longitude,
                                 placeName: city.label, timeKnown: timeKnown,
                                 isPrimary: makePrimary || allProfiles.isEmpty)
            if p.isPrimary {
                for other in allProfiles { other.isPrimary = false }
            }
            context.insert(p)
        }
        Haptics.success()
        onSave?()
        dismiss()
    }
}

struct CityPickerView: View {
    let onPick: (City) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(CityCatalog.search(search)) { city in
                    Button {
                        onPick(city)
                        Haptics.selection()
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .foregroundStyle(Brand.text)
                            Text(city.country)
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search cities")
            .navigationTitle("Birth Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if CityCatalog.search(search).isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No city found",
                        message: "Try the nearest major city — within ~50 km the chart is identical."
                    )
                }
            }
        }
    }
}
