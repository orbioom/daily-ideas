import SwiftUI
import SwiftData

struct HarvestEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("massUnit") private var massRaw = MassUnit.kg.rawValue
    let harvest: Harvest?
    let hive: Hive

    @State private var date = Date.now
    @State private var type = HarvestType.honey
    @State private var weightText = ""
    @State private var frames = 0
    @State private var notes = ""
    @State private var confirmDelete = false

    private var mass: MassUnit { MassUnit(rawValue: massRaw) ?? .kg }
    private var weightInput: Double { Double(weightText) ?? 0 }
    private var valid: Bool { weightInput > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Harvest") {
                    Picker("Product", selection: $type) {
                        ForEach(HarvestType.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0.0", text: $weightText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(16)).frame(width: 80)
                        Text(mass.short).foregroundStyle(Brand.text3)
                    }
                    if type == .honey {
                        Stepper("Frames: \(frames)", value: $frames, in: 0...60)
                    }
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5) }
                if harvest != nil {
                    Section {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete harvest", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(harvest == nil ? "New Harvest" : "Harvest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("Delete this harvest?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let h = harvest { context.delete(h); try? context.save(); Haptics.warning() }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func load() {
        guard let h = harvest else { return }
        date = h.date; type = h.type; weightText = String(format: "%.1f", mass.fromKg(h.weightKg))
        frames = h.frames; notes = h.notes
    }
    private func save() {
        let kg = mass.toKg(weightInput)
        if let h = harvest {
            h.date = date; h.typeRaw = type.rawValue; h.weightKg = kg; h.frames = frames; h.notes = notes
        } else {
            let new = Harvest(date: date, type: type, weightKg: kg, frames: frames, notes: notes, hive: hive)
            context.insert(new); hive.harvests.append(new)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
