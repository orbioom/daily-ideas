import SwiftUI
import SwiftData

struct InspectionEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let inspection: Inspection?
    let hive: Hive

    @State private var date = Date.now
    @State private var queenSeen = false
    @State private var eggsSeen = true
    @State private var queenCells = 0
    @State private var brood = Rating.medium
    @State private var population = Rating.medium
    @State private var stores = Rating.medium
    @State private var temperament = Temperament.normal
    @State private var space = SpaceStatus.balanced
    @State private var mites = ""
    @State private var weather = ""
    @State private var notes = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date)
                    TextField("Weather (e.g. Sunny 24°C)", text: $weather)
                }
                Section("Queen") {
                    Toggle("Queen seen", isOn: $queenSeen)
                    Toggle("Eggs seen", isOn: $eggsSeen)
                    Stepper("Queen cells: \(queenCells)", value: $queenCells, in: 0...50)
                }
                Section("Colony") {
                    ratingPicker("Brood pattern", $brood)
                    ratingPicker("Population", $population)
                    ratingPicker("Stores", $stores)
                    Picker("Temperament", selection: $temperament) {
                        ForEach(Temperament.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Space", selection: $space) {
                        ForEach(SpaceStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section {
                    HStack {
                        Text("Varroa count")
                        Spacer()
                        TextField("0", text: $mites).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 70)
                        Text("/300").foregroundStyle(Brand.text3)
                    }
                    if let m = Int(mites), m > 0 {
                        Text("\(String(format: "%.1f", Double(m)/3.0))% infestation — threshold is \(String(format: "%.0f", Double(BeeLogic.mitesThresholdPer300)/3.0))%.")
                            .font(.caption)
                            .foregroundStyle(m >= BeeLogic.mitesThresholdPer300 ? Brand.danger : Brand.text3)
                    }
                } header: { Text("Mites") } footer: {
                    Text("From an alcohol wash or sugar roll of ~300 bees.")
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...6) }
                if inspection != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete inspection", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(inspection == nil ? "New Inspection" : "Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
            .alert("Delete this inspection?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let i = inspection { context.delete(i); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func ratingPicker(_ label: String, _ binding: Binding<Rating>) -> some View {
        Picker(label, selection: binding) {
            ForEach(Rating.allCases) { Text($0.label).tag($0) }
        }
    }

    private func load() {
        guard let i = inspection else { return }
        date = i.date; queenSeen = i.queenSeen; eggsSeen = i.eggsSeen; queenCells = i.queenCells
        brood = i.brood; population = i.population; stores = i.stores
        temperament = i.temperament; space = i.space; mites = String(i.mitesPer300)
        weather = i.weather; notes = i.notes
    }
    private func save() {
        let m = max(0, Int(mites) ?? 0)
        if let i = inspection {
            i.date = date; i.queenSeen = queenSeen; i.eggsSeen = eggsSeen; i.queenCells = queenCells
            i.broodRaw = brood.rawValue; i.populationRaw = population.rawValue; i.storesRaw = stores.rawValue
            i.temperamentRaw = temperament.rawValue; i.spaceRaw = space.rawValue
            i.mitesPer300 = m; i.weather = weather; i.notes = notes
        } else {
            let new = Inspection(date: date, queenSeen: queenSeen, eggsSeen: eggsSeen, queenCells: queenCells,
                                 brood: brood, population: population, stores: stores, temperament: temperament,
                                 space: space, mitesPer300: m, weather: weather, notes: notes, hive: hive)
            context.insert(new); hive.inspections.append(new)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
