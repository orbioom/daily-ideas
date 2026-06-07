import SwiftUI
import SwiftData

/// Edits an existing flight's details, station loads and fuel plan, with a live
/// weight/CG/status preview. Mutates the flight's snapshot in place on save.
struct FlightEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var flight: Flight
    let aircraft: Aircraft?
    var onSaved: () -> Void

    @State private var name = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var loadWeights: [UUID: String] = [:]
    @State private var fuelGal: Double = 0
    @State private var plannedBurn = ""
    @State private var didInit = false

    private var orderedLoads: [StationLoad] { flight.orderedLoads }
    private var maxFuel: Double { max(fuelGal, aircraft?.usableFuelGal ?? flight.fuelGal, 1) }

    private var loadsForEngine: [(label: String, weight: Double, arm: Double)] {
        orderedLoads.map { ld in
            (label: ld.stationName,
             weight: NumParse.nonNegative(loadWeights[ld.id] ?? ""),
             arm: ld.arm)
        }
    }

    private var inputs: WBEngine.FlightInputs {
        let envelope = flight.envelopeVertices
        let envMax = envelope.map(\.weight).max() ?? 0
        return WBEngine.FlightInputs(
            emptyWeight: flight.emptyWeight,
            emptyArm: flight.emptyArm,
            fuelGal: fuelGal,
            plannedBurnGal: NumParse.nonNegative(plannedBurn),
            taxiBurnGal: flight.taxiBurnGal,
            fuelArm: flight.fuelArm,
            fuelWeightPerGal: flight.fuelWeightPerGal,
            loads: loadsForEngine,
            envelope: envelope,
            maxRampWeight: aircraft?.maxRampWeight ?? envMax,
            maxTakeoffWeight: aircraft?.maxTakeoffWeight ?? envMax,
            maxLandingWeight: aircraft?.maxLandingWeight ?? envMax,
            maxZeroFuelWeight: aircraft?.maxZeroFuelWeight ?? 0
        )
    }

    private var result: WBEngine.FlightResult { WBEngine.evaluate(inputs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Flight") {
                        LabeledField(label: "Name", text: $name, keyboard: .default)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .foregroundStyle(Brand.text2)
                        LabeledField(label: "Notes", text: $notes, keyboard: .default)
                    }
                    Section("Stations (lb)") {
                        if orderedLoads.isEmpty {
                            Text("This flight has no station loads.")
                                .font(.subheadline).foregroundStyle(Brand.text2)
                        } else {
                            ForEach(orderedLoads) { ld in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ld.stationName).foregroundStyle(Brand.text)
                                        Text("Arm \(Fmt.arm(ld.arm)) in")
                                            .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    TextField("0", text: bindingFor(ld))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(Brand.mono(15, weight: .medium))
                                        .foregroundStyle(Brand.text)
                                        .frame(maxWidth: 90)
                                    Text("lb").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(ld.stationName) weight")
                                .accessibilityValue("\(loadWeights[ld.id] ?? "0") pounds")
                            }
                        }
                    }
                    Section("Fuel") {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Fuel").foregroundStyle(Brand.text2)
                                Spacer()
                                Text("\(Fmt.gal(fuelGal)) · \(Fmt.lb(fuelGal * flight.fuelWeightPerGal))")
                                    .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
                            }
                            Slider(value: $fuelGal, in: 0...maxFuel, step: 0.5)
                                .tint(Brand.info)
                                .onChange(of: fuelGal) { _, _ in Haptics.selection() }
                                .accessibilityValue("\(Fmt.gal(fuelGal))")
                        }
                        NumberField(label: "Planned burn (gal)", text: $plannedBurn)
                    }
                    previewSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: initState)
        }
    }

    private var previewSection: some View {
        let ramp = result.scenarios.first { $0.scenario == .ramp }
        let ok = result.allOK
        return Section("Live preview") {
            HStack(spacing: 10) {
                StatTile(value: ramp.map { Fmt.weight($0.point.weight) } ?? "—", label: "Ramp lb")
                StatTile(value: ramp.map { Fmt.arm($0.point.cg) } ?? "—", label: "CG in")
            }
            .listRowBackground(Color.clear)
            HStack {
                StatusDot(color: ok ? Brand.live : Brand.danger)
                Text(ok ? "All scenarios in envelope" : "Out of envelope or over limit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ok ? Brand.live : Brand.danger)
                Spacer()
            }
        }
    }

    private func bindingFor(_ ld: StationLoad) -> Binding<String> {
        Binding(get: { loadWeights[ld.id] ?? "" }, set: { loadWeights[ld.id] = $0 })
    }

    private func initState() {
        guard !didInit else { return }
        didInit = true
        name = flight.name
        date = flight.date
        notes = flight.notes
        fuelGal = flight.fuelGal
        plannedBurn = trimNum(flight.plannedBurnGal)
        for ld in orderedLoads {
            loadWeights[ld.id] = ld.weight == 0 ? "" : trimNum(ld.weight)
        }
    }

    private func save() {
        flight.name = name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled flight" : name.trimmingCharacters(in: .whitespaces)
        flight.date = date
        flight.notes = notes.trimmingCharacters(in: .whitespaces)
        flight.fuelGal = fuelGal
        flight.plannedBurnGal = NumParse.nonNegative(plannedBurn)
        for ld in orderedLoads {
            ld.weight = NumParse.nonNegative(loadWeights[ld.id] ?? "")
        }
        try? context.save()
        Haptics.success()
        onSaved()
        dismiss()
    }

    private func trimNum(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}
