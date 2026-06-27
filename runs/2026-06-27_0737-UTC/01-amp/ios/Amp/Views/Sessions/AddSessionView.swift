import SwiftUI
import SwiftData

struct AddSessionView: View {
    var editing: ChargingSession? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var vehicles: [Vehicle]
    @Query private var settingsArr: [AmpSettings]

    @State private var selectedVehicle: Vehicle? = nil
    @State private var date = Date()
    @State private var kwhText = ""
    @State private var costText = ""
    @State private var startSoCText = ""
    @State private var endSoCText = ""
    @State private var chargerType = ChargerType.l2
    @State private var locationName = ""
    @State private var durationText = ""
    @State private var odometerText = ""
    @State private var notes = ""
    @State private var validationMessage = ""
    @State private var showValidation = false

    private var isEditing: Bool { editing != nil }
    private var currencySymbol: String { settingsArr.first?.currencySymbol ?? "$" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    if vehicles.isEmpty {
                        Text("Add a vehicle first in the Vehicles tab")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Vehicle", selection: $selectedVehicle) {
                            Text("None").tag(Optional<Vehicle>.none)
                            ForEach(vehicles) { v in
                                Text(v.displayName).tag(Optional(v))
                            }
                        }
                    }
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Charge Amount") {
                    HStack {
                        Text("kWh Added")
                        Spacer()
                        TextField("e.g. 35.5", text: $kwhText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kWh")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Cost (\(currencySymbol))")
                        Spacer()
                        TextField("e.g. 8.20", text: $costText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("State of Charge (optional)") {
                    HStack {
                        Text("Start %")
                        Spacer()
                        TextField("e.g. 20", text: $startSoCText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("%").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("End %")
                        Spacer()
                        TextField("e.g. 85", text: $endSoCText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("%").foregroundStyle(.secondary)
                    }
                }
                Section("Charger") {
                    Picker("Type", selection: $chargerType) {
                        ForEach(ChargerType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    TextField("Location (optional)", text: $locationName)
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("minutes", text: $durationText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("min").foregroundStyle(.secondary)
                    }
                }
                Section("Optional") {
                    HStack {
                        Text("Odometer")
                        Spacer()
                        TextField("miles", text: $odometerText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("mi").foregroundStyle(.secondary)
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Session" : "Log Charge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(kwhText.isEmpty || costText.isEmpty)
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let s = editing else {
            selectedVehicle = vehicles.first
            return
        }
        selectedVehicle = s.vehicle
        date = s.date
        kwhText = String(format: "%.2f", s.kwhAdded)
        costText = String(format: "%.2f", s.cost)
        if s.startSoC > 0 { startSoCText = "\(Int(s.startSoC))" }
        if s.endSoC > 0 { endSoCText = "\(Int(s.endSoC))" }
        chargerType = s.chargerType
        locationName = s.locationName
        if s.durationMinutes > 0 { durationText = "\(Int(s.durationMinutes))" }
        if s.odometer > 0 { odometerText = "\(Int(s.odometer))" }
        notes = s.notes
    }

    private func save() {
        guard let kwh = Double(kwhText.replacingOccurrences(of: ",", with: ".")),
              kwh > 0 else {
            validationMessage = "Please enter a valid kWh amount."
            showValidation = true
            return
        }
        guard let cost = Double(costText.replacingOccurrences(of: ",", with: ".")),
              cost >= 0 else {
            validationMessage = "Please enter a valid cost."
            showValidation = true
            return
        }
        let startSoC = Double(startSoCText) ?? 0
        let endSoC = Double(endSoCText) ?? 0
        let duration = Double(durationText) ?? 0
        let odometer = Double(odometerText) ?? 0

        if let s = editing {
            s.date = date
            s.kwhAdded = kwh
            s.cost = cost
            s.startSoC = startSoC
            s.endSoC = endSoC
            s.chargerType = chargerType
            s.locationName = locationName
            s.durationMinutes = duration
            s.odometer = odometer
            s.notes = notes
            s.vehicle = selectedVehicle
        } else {
            let s = ChargingSession(
                date: date, kwhAdded: kwh, cost: cost,
                startSoC: startSoC, endSoC: endSoC,
                chargerType: chargerType, locationName: locationName,
                durationMinutes: duration, odometer: odometer,
                notes: notes, vehicle: selectedVehicle
            )
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}
