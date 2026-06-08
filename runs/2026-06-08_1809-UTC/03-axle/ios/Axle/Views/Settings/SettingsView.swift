import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage("axle.volumeUnit") private var volumeUnitRaw = VolumeUnit.liter.rawValue
    @AppStorage("axle.currency") private var currency = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("axle.haptics") private var haptics = true

    @State private var showReset = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "INR", "JPY", "BRL", "MXN", "ZAR", "NGN"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Distance", selection: $distanceUnitRaw) {
                        Text("Kilometers").tag(DistanceUnit.km.rawValue)
                        Text("Miles").tag(DistanceUnit.mi.rawValue)
                    }
                    Picker("Volume", selection: $volumeUnitRaw) {
                        Text("Liters").tag(VolumeUnit.liter.rawValue)
                        Text("Gallons (US)").tag(VolumeUnit.gallon.rawValue)
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { Text($0).tag($0) }
                    }
                } footer: {
                    Text("Data is stored in metric and converted for display, so changing units never alters your history.")
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section {
                    Button(role: .destructive) { showReset = true } label: {
                        Label("Delete all vehicles & data", systemImage: "trash")
                    }
                } footer: {
                    Text("Axle keeps everything on this device. Nothing is uploaded.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Delete everything?", isPresented: $showReset, titleVisibility: .visible) {
                Button("Delete all", role: .destructive, action: resetAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every vehicle, fill-up, service and reminder. This can't be undone.")
            }
        }
    }

    private func resetAll() {
        try? context.delete(model: FuelEntry.self)
        try? context.delete(model: ServiceRecord.self)
        try? context.delete(model: ServiceReminder.self)
        try? context.delete(model: Vehicle.self)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
