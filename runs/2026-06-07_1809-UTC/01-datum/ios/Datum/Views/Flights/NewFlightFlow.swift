import SwiftUI
import SwiftData

/// The new-flight flow: first pick an aircraft, then fill the loading form with a
/// live weight/CG/status preview, then save a snapshotted Flight.
struct NewFlightFlow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Aircraft.createdAt, order: .reverse) private var aircraft: [Aircraft]

    @State private var selected: Aircraft?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if aircraft.isEmpty {
                    EmptyStateView(
                        icon: "airplane.circle",
                        title: "No aircraft",
                        message: "Add an aircraft profile in the Aircraft tab before planning a flight."
                    )
                } else {
                    List {
                        Section {
                            ForEach(aircraft) { ac in
                                Button {
                                    Haptics.selection()
                                    selected = ac
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(ac.tailNumber)
                                                .font(Brand.mono(16, weight: .semibold))
                                                .foregroundStyle(Brand.text)
                                            Text(ac.model)
                                                .font(.subheadline)
                                                .foregroundStyle(Brand.text2)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(Brand.text3)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .accessibilityHint("Selects this aircraft for the new flight")
                            }
                        } header: {
                            Text("Choose an aircraft")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("New Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $selected) { ac in
                FlightFormView(aircraft: ac, onSaved: { dismiss() })
            }
        }
    }
}

/// The flight loading form. Builds a draft from the aircraft's defaults, edits a
/// weight per station + fuel/burn, and shows a live preview before saving.
struct FlightFormView: View {
    @Environment(\.modelContext) private var context
    let aircraft: Aircraft
    var onSaved: () -> Void

    @State private var name = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var stationWeights: [UUID: String] = [:]
    @State private var fuelGal: Double = 0
    @State private var plannedBurn = ""
    @State private var didInit = false

    private var orderedStations: [Station] { aircraft.orderedStations }

    private var loadsForEngine: [(label: String, weight: Double, arm: Double)] {
        orderedStations.map { st in
            (label: st.name,
             weight: NumParse.nonNegative(stationWeights[st.id] ?? ""),
             arm: st.arm)
        }
    }

    private var inputs: WBEngine.FlightInputs {
        WBEngine.FlightInputs(
            emptyWeight: aircraft.emptyWeight,
            emptyArm: aircraft.emptyArm,
            fuelGal: fuelGal,
            plannedBurnGal: NumParse.nonNegative(plannedBurn),
            taxiBurnGal: aircraft.taxiBurnGal,
            fuelArm: aircraft.fuelArm,
            fuelWeightPerGal: aircraft.fuelWeightPerGal,
            loads: loadsForEngine,
            envelope: aircraft.orderedEnvelope.map { EnvelopeVertex(cg: $0.cgArm, weight: $0.weight) },
            maxRampWeight: aircraft.maxRampWeight,
            maxTakeoffWeight: aircraft.maxTakeoffWeight,
            maxLandingWeight: aircraft.maxLandingWeight,
            maxZeroFuelWeight: aircraft.maxZeroFuelWeight
        )
    }

    private var result: WBEngine.FlightResult { WBEngine.evaluate(inputs) }

    private var overStationLimits: [String] {
        orderedStations.compactMap { st in
            let w = NumParse.nonNegative(stationWeights[st.id] ?? "")
            if st.maxWeight > 0, w > st.maxWeight {
                return "\(st.name) exceeds its \(Fmt.lb(st.maxWeight)) limit."
            }
            return nil
        }
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            Form {
                detailsSection
                stationsSection
                fuelSection
                previewSection
                if !overStationLimits.isEmpty {
                    Section("Warnings") {
                        ForEach(overStationLimits, id: \.self) { msg in
                            Label(msg, systemImage: "exclamationmark.triangle")
                                .font(.subheadline)
                                .foregroundStyle(Brand.warn)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(aircraft.tailNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.fontWeight(.semibold)
            }
        }
        .onAppear(perform: initDefaults)
    }

    private var detailsSection: some View {
        Section("Flight") {
            LabeledField(label: "Name", text: $name, keyboard: .default)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .foregroundStyle(Brand.text2)
            LabeledField(label: "Notes", text: $notes, keyboard: .default)
        }
    }

    private var stationsSection: some View {
        Section {
            if orderedStations.isEmpty {
                Text("This aircraft has no stations. Add some in the Aircraft tab.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                ForEach(orderedStations) { st in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(st.name).foregroundStyle(Brand.text)
                            Text("Arm \(Fmt.arm(st.arm)) in" + (st.maxWeight > 0 ? " · max \(Fmt.weight(st.maxWeight))" : ""))
                                .font(Brand.mono(10))
                                .foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        TextField("0", text: bindingFor(st))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(Brand.mono(15, weight: .medium))
                            .foregroundStyle(Brand.text)
                            .frame(maxWidth: 90)
                        Text("lb").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(st.name) weight")
                    .accessibilityValue("\(stationWeights[st.id] ?? "0") pounds")
                }
            }
        } header: {
            Text("Stations (lb)")
        }
    }

    private var fuelSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Fuel").foregroundStyle(Brand.text2)
                    Spacer()
                    Text("\(Fmt.gal(fuelGal)) · \(Fmt.lb(fuelGal * aircraft.fuelWeightPerGal))")
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $fuelGal, in: 0...max(1, aircraft.usableFuelGal), step: 0.5) {
                    Text("Fuel")
                } minimumValueLabel: {
                    Text("0").font(Brand.mono(10)).foregroundStyle(Brand.text3)
                } maximumValueLabel: {
                    Text(Fmt.gal(aircraft.usableFuelGal)).font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                .tint(Brand.info)
                .onChange(of: fuelGal) { _, _ in Haptics.selection() }
                .accessibilityValue("\(Fmt.gal(fuelGal)) of \(Fmt.gal(aircraft.usableFuelGal)) usable")
            }
            NumberField(label: "Planned burn (gal)", text: $plannedBurn)
        } header: {
            Text("Fuel (max \(Fmt.gal(aircraft.usableFuelGal)) usable)")
        } footer: {
            Text("Taxi burn of \(Fmt.gal(aircraft.taxiBurnGal)) is applied automatically before takeoff.")
        }
    }

    private var previewSection: some View {
        let ramp = result.scenarios.first { $0.scenario == .ramp }
        let takeoff = result.scenarios.first { $0.scenario == .takeoff }
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
            if let range = result.allowableCGRange, let to = takeoff {
                InfoRow(label: "Takeoff CG range",
                        value: "\(Fmt.arm(range.lowerBound))–\(Fmt.arm(range.upperBound)) in", mono: true)
                InfoRow(label: "Takeoff CG", value: Fmt.arm(to.point.cg) + " in", mono: true)
            }
        }
    }

    private func bindingFor(_ st: Station) -> Binding<String> {
        Binding(
            get: { stationWeights[st.id] ?? "" },
            set: { stationWeights[st.id] = $0 }
        )
    }

    private func initDefaults() {
        guard !didInit else { return }
        didInit = true
        for st in orderedStations {
            stationWeights[st.id] = st.defaultWeight == 0 ? "" : trimNum(st.defaultWeight)
        }
        fuelGal = aircraft.usableFuelGal
        plannedBurn = "0"
        name = "Flight \(Fmt.date(date))"
    }

    private func save() {
        let flight = Flight(
            name: name.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled flight" : name.trimmingCharacters(in: .whitespaces),
            date: date,
            aircraftTail: aircraft.tailNumber,
            aircraftModel: aircraft.model,
            emptyWeight: aircraft.emptyWeight,
            emptyArm: aircraft.emptyArm,
            fuelGal: fuelGal,
            plannedBurnGal: NumParse.nonNegative(plannedBurn),
            taxiBurnGal: aircraft.taxiBurnGal,
            fuelArm: aircraft.fuelArm,
            fuelWeightPerGal: aircraft.fuelWeightPerGal,
            notes: notes.trimmingCharacters(in: .whitespaces),
            envelopeData: EnvelopeVertex.encode(aircraft.orderedEnvelope.map { EnvelopeVertex(cg: $0.cgArm, weight: $0.weight) })
        )
        flight.loads = orderedStations.enumerated().map { idx, st in
            StationLoad(stationName: st.name, arm: st.arm,
                        weight: NumParse.nonNegative(stationWeights[st.id] ?? ""),
                        order: idx, flight: flight)
        }
        context.insert(flight)
        try? context.save()
        Haptics.success()
        onSaved()
    }

    private func trimNum(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}
