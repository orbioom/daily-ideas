import SwiftUI
import SwiftData

struct CatchEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultSpecies") private var defaultSpecies = "Brown Trout"
    @AppStorage("useMetric") private var useMetric = false
    @Query(sort: \Pattern.name) private var patterns: [Pattern]

    var entry: Catch?

    @State private var date = Date.now
    @State private var species = ""
    @State private var location = ""
    @State private var length = 12.0
    @State private var waterTemp = 54.0
    @State private var airTemp = 65.0
    @State private var weather: Weather = .partly
    @State private var patternName = ""
    @State private var released = true
    @State private var notes = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Fish") {
                        TextField("Species", text: $species)
                        TextField("Location", text: $location)
                        DatePicker("When", selection: $date)
                        Stepper("Length: \(Units.length(length, metric: useMetric))",
                                value: $length, in: 0...50, step: 0.5)
                        Toggle("Released", isOn: $released)
                    }.listRowBackground(Color.clear)

                    Section("The fly") {
                        Picker("Pattern", selection: $patternName) {
                            Text("None").tag("")
                            ForEach(patterns) { p in Text(p.name).tag(p.name) }
                        }
                    }.listRowBackground(Color.clear)

                    Section("Conditions") {
                        Picker("Weather", selection: $weather) {
                            ForEach(Weather.allCases) { w in Text(w.label).tag(w) }
                        }
                        Stepper("Water: \(Units.temp(waterTemp, metric: useMetric))",
                                value: $waterTemp, in: 32...80, step: 1)
                        Stepper("Air: \(Units.temp(airTemp, metric: useMetric))",
                                value: $airTemp, in: 20...110, step: 1)
                    }.listRowBackground(Color.clear)

                    Section("Notes") {
                        TextField("Optional", text: $notes, axis: .vertical).lineLimit(2...5)
                    }.listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(entry == nil ? "Log a catch" : "Edit catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let c = entry {
            date = c.date; species = c.species; location = c.location
            length = c.lengthInches; waterTemp = c.waterTempF; airTemp = c.airTempF
            weather = c.weather; patternName = c.patternName; released = c.released; notes = c.notes
        } else {
            species = defaultSpecies
            patternName = patterns.first { $0.isFavorite }?.name ?? patterns.first?.name ?? ""
        }
    }

    private func save() {
        if let c = entry {
            c.date = date; c.species = species; c.location = location
            c.lengthInches = length; c.waterTempF = waterTemp; c.airTempF = airTemp
            c.weatherRaw = weather.rawValue; c.patternName = patternName
            c.released = released; c.notes = notes
        } else {
            let c = Catch(date: date, species: species, location: location, lengthInches: length,
                          waterTempF: waterTemp, airTempF: airTemp, weather: weather,
                          patternName: patternName, released: released, notes: notes)
            context.insert(c)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
