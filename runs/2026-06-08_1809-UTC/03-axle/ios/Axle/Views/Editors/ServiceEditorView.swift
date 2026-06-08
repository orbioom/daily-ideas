import SwiftUI
import SwiftData

struct ServiceEditorView: View {
    let vehicle: Vehicle
    enum Mode { case create, edit(ServiceRecord) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue

    @State private var date = Date()
    @State private var type: ServiceType = .oilChange
    @State private var odometerText = ""
    @State private var costText = ""
    @State private var notes = ""

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(ServiceType.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Odometer (\(distanceUnit.label))")
                        Spacer()
                        TextField("0", text: $odometerText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("0", text: $costText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                }
                Section("Notes") {
                    TextField("What was done…", text: $notes, axis: .vertical).lineLimit(2...5)
                }
                if case let .edit(r) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(r); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete record", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Service" : "Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        switch mode {
        case .create:
            odometerText = String(format: "%.0f", distanceUnit.fromKm(vehicle.odometerKm))
        case .edit(let r):
            date = r.date; type = r.type; notes = r.notes
            odometerText = String(format: "%.0f", distanceUnit.fromKm(r.odometerKm))
            costText = String(format: "%.2f", r.cost)
        }
    }

    private func save() {
        let odoKm = distanceUnit.toKm(Double(odometerText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        let cost = Double(costText.replacingOccurrences(of: ",", with: ".")) ?? 0
        switch mode {
        case .create:
            let r = ServiceRecord(date: date, odometerKm: odoKm, type: type, cost: cost, notes: notes)
            r.vehicle = vehicle
            context.insert(r)
        case .edit(let r):
            r.date = date; r.type = type; r.odometerKm = odoKm; r.cost = cost; r.notes = notes
        }
        if odoKm > vehicle.odometerKm { vehicle.odometerKm = odoKm }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
