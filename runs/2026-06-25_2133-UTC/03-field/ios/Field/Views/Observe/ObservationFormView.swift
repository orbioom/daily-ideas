import SwiftUI
import SwiftData

struct ObservationFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [FieldSettings]

    let existing: Observation?

    @State private var date: Date
    @State private var speciesName: String
    @State private var speciesClass: SpeciesClass
    @State private var commonName: String
    @State private var count: Int
    @State private var locationName: String
    @State private var habitat: String
    @State private var quality: ObservationQuality
    @State private var weather: WeatherConditions
    @State private var behavior: String
    @State private var notes: String
    @State private var isLifer: Bool
    @State private var tripName: String
    @State private var showError = false

    init(observation: Observation?) {
        self.existing = observation
        _date = State(initialValue: observation?.date ?? .now)
        _speciesName = State(initialValue: observation?.speciesName ?? "")
        _speciesClass = State(initialValue: observation?.speciesClass ?? .bird)
        _commonName = State(initialValue: observation?.commonName ?? "")
        _count = State(initialValue: observation?.count ?? 1)
        _locationName = State(initialValue: observation?.locationName ?? "")
        _habitat = State(initialValue: observation?.habitat ?? "")
        _quality = State(initialValue: observation?.quality ?? .good)
        _weather = State(initialValue: observation?.weather ?? .sunny)
        _behavior = State(initialValue: observation?.behavior ?? "")
        _notes = State(initialValue: observation?.notes ?? "")
        _isLifer = State(initialValue: observation?.isLifer ?? false)
        _tripName = State(initialValue: observation?.tripName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Species") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Common or scientific", text: $speciesName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Common name")
                        Spacer()
                        TextField("Optional", text: $commonName)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Class", selection: $speciesClass) {
                        ForEach(SpeciesClass.allCases) { c in
                            Label("\(c.emoji) \(c.rawValue)", systemImage: c.sfSymbol).tag(c)
                        }
                    }
                    Toggle("Life list first (Lifer!)", isOn: $isLifer)
                        .tint(FieldTheme.fern)
                }
                Section("When & Where") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Location")
                        Spacer()
                        TextField("e.g. City Park", text: $locationName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Habitat")
                        Spacer()
                        TextField("e.g. woodland edge", text: $habitat)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Trip")
                        Spacer()
                        TextField("Optional", text: $tripName)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Count & Conditions") {
                    Stepper("Count: \(count)", value: $count, in: 1...9999)
                    Picker("View quality", selection: $quality) {
                        ForEach(ObservationQuality.allCases) { q in Text(q.rawValue).tag(q) }
                    }
                    Picker("Weather", selection: $weather) {
                        ForEach(WeatherConditions.allCases) { w in
                            Label(w.rawValue, systemImage: w.sfSymbol).tag(w)
                        }
                    }
                }
                Section("Behaviour & Notes") {
                    HStack {
                        Text("Behaviour")
                        Spacer()
                        TextField("e.g. foraging", text: $behavior)
                            .multilineTextAlignment(.trailing)
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 70)
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle(existing == nil ? "New Sighting" : "Edit Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(speciesName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(FieldTheme.fern)
                }
            }
            .alert("Please enter a species name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func save() {
        let trimmed = speciesName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }
        if let o = existing {
            o.date = date; o.speciesName = trimmed; o.speciesClass = speciesClass
            o.commonName = commonName; o.count = count; o.locationName = locationName
            o.habitat = habitat; o.quality = quality; o.weather = weather
            o.behavior = behavior; o.notes = notes; o.isLifer = isLifer; o.tripName = tripName
        } else {
            let o = Observation(date: date, speciesName: trimmed, speciesClass: speciesClass,
                commonName: commonName, count: count, locationName: locationName,
                habitat: habitat, quality: quality, weather: weather,
                behavior: behavior, notes: notes, isLifer: isLifer, tripName: tripName)
            context.insert(o)
            if isLifer && (allSettings.first?.liferAlerts == true) {
                FieldHaptics.success()
            }
        }
        try? context.save()
        dismiss()
    }
}
