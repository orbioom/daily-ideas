import SwiftUI
import SwiftData

struct FuelEditorView: View {
    let vehicle: Vehicle
    enum Mode { case create, edit(FuelEntry) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("axle.volumeUnit") private var volumeUnitRaw = VolumeUnit.liter.rawValue

    @State private var date = Date()
    @State private var odometerText = ""
    @State private var volumeText = ""
    @State private var costText = ""
    @State private var isFull = true

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var volumeUnit: VolumeUnit { VolumeUnit(rawValue: volumeUnitRaw) ?? .liter }
    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    private var odo: Double? {
        let v = Double(odometerText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return v
    }
    private var volume: Double? {
        let v = Double(volumeText.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0 else { return nil }
        return v
    }
    private var canSave: Bool { odo != nil && volume != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    HStack {
                        Text("Odometer (\(distanceUnit.label))")
                        Spacer()
                        TextField("0", text: $odometerText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                    HStack {
                        Text("Volume (\(volumeUnit.label))")
                        Spacer()
                        TextField("0", text: $volumeText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                    HStack {
                        Text("Total cost")
                        Spacer()
                        TextField("0", text: $costText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 120)
                    }
                }
                Section {
                    Toggle("Filled the tank", isOn: $isFull)
                } footer: {
                    Text("Mark every complete fill so Axle can measure economy accurately, even when you also log partial top-ups.")
                }
                if case let .edit(e) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(e); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete fill-up", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Fill-up" : "Add Fill-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        switch mode {
        case .create:
            odometerText = String(format: "%.0f", distanceUnit.fromKm(vehicle.odometerKm))
        case .edit(let e):
            date = e.date
            odometerText = String(format: "%.0f", distanceUnit.fromKm(e.odometerKm))
            volumeText = String(format: "%.2f", volumeUnit.fromLiters(e.liters))
            costText = String(format: "%.2f", e.totalCost)
            isFull = e.isFullTank
        }
    }

    private func save() {
        guard let odo, let volume else { return }
        let odoKm = distanceUnit.toKm(odo)
        let liters = volumeUnit.toLiters(volume)
        let cost = Double(costText.replacingOccurrences(of: ",", with: ".")) ?? 0
        switch mode {
        case .create:
            let e = FuelEntry(date: date, odometerKm: odoKm, liters: liters,
                              totalCost: cost, isFullTank: isFull)
            e.vehicle = vehicle
            context.insert(e)
        case .edit(let e):
            e.date = date; e.odometerKm = odoKm; e.liters = liters
            e.totalCost = cost; e.isFullTank = isFull
        }
        if odoKm > vehicle.odometerKm { vehicle.odometerKm = odoKm }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
