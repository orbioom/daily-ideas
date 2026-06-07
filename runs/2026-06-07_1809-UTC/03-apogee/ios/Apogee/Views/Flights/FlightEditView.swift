import SwiftUI
import SwiftData

/// Edit an existing flight: enter the measured altitude, delay used, recovery,
/// wind and notes. The measured altitude is what drives the predicted-vs-actual
/// comparison and the logbook accuracy insight.
struct FlightEditView: View {
    @Bindable var flight: Flight
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("apogee.units") private var unitsRaw = LengthUnit.meters.rawValue

    @State private var date = Date()
    @State private var actualAltitude = ""
    @State private var delayUsed = ""
    @State private var wind = ""
    @State private var recovery: Recovery = .parachute
    @State private var notes = ""

    private var units: LengthUnit { LengthUnit(rawValue: unitsRaw) ?? .meters }

    // Measured altitude is optional (blank = not recorded); when present it must
    // be non-negative.
    private var actualValid: Bool {
        let t = actualAltitude.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return true }
        guard let v = Double(t.replacingOccurrences(of: ",", with: ".")), v >= 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } header: {
                    Text("When")
                }

                Section {
                    HStack {
                        Text("Measured altitude").foregroundStyle(Brand.text2)
                        Spacer()
                        TextField("0", text: $actualAltitude)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Brand.mono(15, weight: .medium))
                            .foregroundStyle(actualValid ? Brand.text : Brand.danger)
                            .frame(maxWidth: 100)
                            .accessibilityLabel("Measured altitude in \(units.label)")
                        Text(units.symbol).foregroundStyle(Brand.text3).font(.subheadline)
                    }
                    HStack {
                        Text("Delay used").foregroundStyle(Brand.text2)
                        Spacer()
                        TextField("0", text: $delayUsed)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Brand.mono(15, weight: .medium))
                            .frame(maxWidth: 100)
                            .accessibilityLabel("Ejection delay used")
                        Text("s").foregroundStyle(Brand.text3).font(.subheadline)
                    }
                } header: {
                    Text("Results")
                } footer: {
                    Text("Predicted apogee was \(Format.altitude(flight.predictedAltitudeM, unit: units)). Leave measured blank if you didn't get a reading.")
                }

                Section("Recovery & conditions") {
                    Picker("Recovery", selection: $recovery) {
                        ForEach(Recovery.allCases) { r in
                            Label(r.label, systemImage: r.icon).tag(r)
                        }
                    }
                    HStack {
                        Text("Wind").foregroundStyle(Brand.text2)
                        Spacer()
                        TextField("0", text: $wind)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Brand.mono(15, weight: .medium))
                            .frame(maxWidth: 100)
                            .accessibilityLabel("Wind speed in kph")
                        Text("kph").foregroundStyle(Brand.text3).font(.subheadline)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!actualValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        date = flight.date
        // Show measured altitude in the user's display unit; blank if unrecorded.
        if flight.hasActual {
            actualAltitude = Format.number(units.from(meters: flight.actualAltitudeM), decimals: 0)
        }
        delayUsed = trimmed(flight.delayUsedS)
        wind = trimmed(flight.windKph)
        recovery = flight.recovery
        notes = flight.notes
    }

    private func save() {
        guard actualValid else { return }
        Haptics.success()
        flight.date = date
        // Parse the measured altitude back into metres for storage.
        let t = actualAltitude.trimmingCharacters(in: .whitespaces)
        if t.isEmpty {
            flight.actualAltitudeM = 0
        } else if let v = Double(t.replacingOccurrences(of: ",", with: ".")), v >= 0 {
            flight.actualAltitudeM = units == .feet ? v / 3.280839895 : v
        }
        if let d = Double(delayUsed.replacingOccurrences(of: ",", with: ".")), d >= 0 {
            flight.delayUsedS = d
        }
        if let w = Double(wind.replacingOccurrences(of: ",", with: ".")), w >= 0 {
            flight.windKph = w
        }
        flight.recovery = recovery
        flight.notes = notes
        try? context.save()
        dismiss()
    }

    private func trimmed(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }
}
