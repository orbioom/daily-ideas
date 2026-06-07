import SwiftUI
import SwiftData

struct SightingEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]

    let existing: Sighting?
    /// When launched from a trip, pre-binds the sighting to it.
    let trip: Trip?

    @State private var selectedSpecies: Species?
    @State private var date = Date()
    @State private var location = ""
    @State private var count = 1
    @State private var notes = ""
    @State private var selectedTrip: Trip?
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button { Haptics.tap(); showingPicker = true } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Species").font(.caption).foregroundStyle(Brand.text3)
                                Text(selectedSpecies?.commonName ?? "Choose a bird")
                                    .font(.headline)
                                    .foregroundStyle(selectedSpecies == nil ? Brand.text3 : Brand.text)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
                        }
                        .glassCard()
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .tint(Brand.text).foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Location").foregroundStyle(Brand.text2)
                            Spacer()
                            TextField("Where?", text: $location).multilineTextAlignment(.trailing)
                                .foregroundStyle(Brand.text)
                        }
                        Divider().overlay(Brand.hairline)
                        Stepper("Count: \(count)", value: $count, in: 1...9999)
                            .foregroundStyle(Brand.text2)
                        Divider().overlay(Brand.hairline)
                        HStack {
                            Text("Trip").foregroundStyle(Brand.text2)
                            Spacer()
                            Picker("Trip", selection: $selectedTrip) {
                                Text("None").tag(Trip?.none)
                                ForEach(trips) { t in Text(t.name).tag(Trip?.some(t)) }
                            }.tint(Brand.text)
                        }
                    }
                    .font(.subheadline)
                    .glassCard()

                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle(text: "Notes")
                        TextField("Behaviour, plumage, weather…", text: $notes, axis: .vertical)
                            .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
                    }
                    .glassCard()
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Sighting" : "Edit Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(selectedSpecies == nil)
                }
            }
            .sheet(isPresented: $showingPicker) {
                SpeciesPickerView(selection: $selectedSpecies)
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let e = existing {
            selectedSpecies = e.species; date = e.date; location = e.location
            count = e.count; notes = e.notes; selectedTrip = e.trip
        } else if let trip {
            selectedTrip = trip
            location = trip.location
            date = trip.date
        }
    }

    private func save() {
        guard let sp = selectedSpecies else { return }
        let s: Sighting
        if let existing { s = existing } else {
            s = Sighting(date: date, location: location, count: count, notes: notes, species: sp, trip: selectedTrip)
            context.insert(s)
        }
        s.species = sp
        s.date = date
        s.location = location
        s.count = max(1, count)
        s.notes = notes
        s.trip = selectedTrip
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
