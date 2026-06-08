import SwiftUI
import SwiftData

struct VehicleEditorView: View {
    enum Mode { case create, edit(Vehicle) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue

    @State private var name = ""
    @State private var make = ""
    @State private var model = ""
    @State private var yearText = ""
    @State private var plate = ""
    @State private var odometerText = ""
    @State private var fuelType: FuelType = .petrol

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    TextField("Name (e.g. Daily Driver)", text: $name)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Year", text: $yearText).keyboardType(.numberPad)
                    TextField("Plate (optional)", text: $plate)
                        .textInputAutocapitalization(.characters)
                }
                Section("Details") {
                    Picker("Fuel type", selection: $fuelType) {
                        ForEach(FuelType.allCases) { Text($0.title).tag($0) }
                    }
                    HStack {
                        Text("Odometer (\(distanceUnit.label))")
                        Spacer()
                        TextField("0", text: $odometerText)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 120)
                    }
                }
                if case let .edit(v) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(v); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete vehicle", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Vehicle" : "Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(v) = mode {
            name = v.name; make = v.make; model = v.model
            yearText = v.year > 0 ? "\(v.year)" : ""
            plate = v.plate
            odometerText = String(format: "%.0f", distanceUnit.fromKm(v.odometerKm))
            fuelType = v.fuelType
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let year = Int(yearText) ?? 0
        let odoEntered = Double(odometerText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let odoKm = distanceUnit.toKm(max(0, odoEntered))
        switch mode {
        case .create:
            let v = Vehicle(name: trimmed, make: make, model: model, year: year,
                            plate: plate, odometerKm: odoKm, fuelType: fuelType)
            context.insert(v)
        case .edit(let v):
            v.name = trimmed; v.make = make; v.model = model; v.year = year
            v.plate = plate; v.odometerKm = odoKm; v.fuelType = fuelType
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
