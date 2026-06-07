import SwiftUI
import SwiftData

/// Editable draft of a station (kept as strings for clean text-field binding).
private struct StationDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var arm: String = ""
    var maxWeight: String = ""
    var defaultWeight: String = ""
}

/// Editable draft of an envelope vertex.
private struct EnvelopeDraft: Identifiable {
    let id = UUID()
    var cg: String = ""
    var weight: String = ""
}

/// Creates or edits an aircraft profile, including its stations and CG envelope,
/// with live validation and a mini envelope preview. Commits to SwiftData on save.
struct AircraftEditView: View {
    enum Mode {
        case create(defaultFuelLbPerGal: Double)
        case edit(Aircraft)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let mode: Mode
    private let existing: Aircraft?

    @State private var tailNumber = ""
    @State private var model = ""
    @State private var emptyWeight = ""
    @State private var emptyArm = ""
    @State private var maxRamp = ""
    @State private var maxTakeoff = ""
    @State private var maxLanding = ""
    @State private var maxZeroFuel = ""
    @State private var fuelCapacity = ""
    @State private var usableFuel = ""
    @State private var fuelArm = ""
    @State private var fuelLbPerGal = ""
    @State private var taxiBurn = ""

    @State private var stations: [StationDraft] = []
    @State private var envelope: [EnvelopeDraft] = []
    @State private var showValidation = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .edit(let ac): existing = ac
        case .create: existing = nil
        }
    }

    private var isEditing: Bool { existing != nil }

    private var previewVertices: [EnvelopeVertex] {
        envelope.compactMap { d in
            guard NumParse.isValid(d.cg), NumParse.isValid(d.weight) else { return nil }
            return EnvelopeVertex(cg: NumParse.any(d.cg), weight: NumParse.any(d.weight))
        }
    }

    // MARK: - Validation

    private var validationErrors: [String] {
        var errs: [String] = []
        if tailNumber.trimmingCharacters(in: .whitespaces).isEmpty {
            errs.append("Tail number is required.")
        }
        if NumParse.nonNegative(emptyWeight) <= 0 {
            errs.append("Empty weight must be greater than zero.")
        }
        if NumParse.nonNegative(emptyArm) <= 0 {
            errs.append("Empty arm must be greater than zero.")
        }
        if NumParse.nonNegative(maxTakeoff) <= 0 {
            errs.append("Max takeoff weight must be greater than zero.")
        }
        if NumParse.nonNegative(usableFuel) > NumParse.nonNegative(fuelCapacity), NumParse.nonNegative(fuelCapacity) > 0 {
            errs.append("Usable fuel cannot exceed total capacity.")
        }
        if NumParse.nonNegative(fuelLbPerGal) <= 0 {
            errs.append("Fuel weight per gallon must be greater than zero.")
        }
        let validVertices = previewVertices.count
        if validVertices < 3 {
            errs.append("Add at least three CG envelope points.")
        }
        if stations.contains(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            errs.append("Every station needs a name.")
        }
        return errs
    }

    private var canSave: Bool { validationErrors.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    identitySection
                    weightSection
                    limitsSection
                    fuelSection
                    stationsSection
                    envelopeSection
                    if !previewVertices.isEmpty {
                        previewSection
                    }
                    if showValidation && !validationErrors.isEmpty {
                        validationSection
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Aircraft" : "New Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section("Identity") {
            LabeledField(label: "Tail number", text: $tailNumber, keyboard: .default)
            LabeledField(label: "Model", text: $model, keyboard: .default)
        }
    }

    private var weightSection: some View {
        Section("Empty weight") {
            NumberField(label: "Empty weight (lb)", text: $emptyWeight)
            NumberField(label: "Empty arm (in)", text: $emptyArm)
        }
    }

    private var limitsSection: some View {
        Section {
            NumberField(label: "Max ramp (lb)", text: $maxRamp)
            NumberField(label: "Max takeoff (lb)", text: $maxTakeoff)
            NumberField(label: "Max landing (lb)", text: $maxLanding)
            NumberField(label: "Max zero-fuel (lb)", text: $maxZeroFuel)
        } header: {
            Text("Weight limits")
        } footer: {
            Text("Use 0 for any limit that does not apply to this aircraft.")
        }
    }

    private var fuelSection: some View {
        Section("Fuel") {
            NumberField(label: "Capacity (gal)", text: $fuelCapacity)
            NumberField(label: "Usable (gal)", text: $usableFuel)
            NumberField(label: "Fuel arm (in)", text: $fuelArm)
            NumberField(label: "Weight per gal (lb)", text: $fuelLbPerGal)
            NumberField(label: "Taxi burn (gal)", text: $taxiBurn)
        }
    }

    private var stationsSection: some View {
        Section {
            ForEach($stations) { $station in
                VStack(spacing: 8) {
                    LabeledField(label: "Name", text: $station.name, keyboard: .default)
                    HStack(spacing: 10) {
                        CompactNumberField(label: "Arm", text: $station.arm)
                        CompactNumberField(label: "Max", text: $station.maxWeight)
                        CompactNumberField(label: "Default", text: $station.defaultWeight)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { stations.remove(atOffsets: $0) }
            .onMove { stations.move(fromOffsets: $0, toOffset: $1) }

            Button {
                Haptics.tap()
                stations.append(StationDraft())
            } label: {
                Label("Add station", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Stations")
                Spacer()
                if !stations.isEmpty { EditButton().font(.subheadline) }
            }
        } footer: {
            Text("Max of 0 means no per-station limit. Reorder with the edit button.")
        }
    }

    private var envelopeSection: some View {
        Section {
            ForEach($envelope) { $point in
                HStack(spacing: 10) {
                    CompactNumberField(label: "CG (in)", text: $point.cg)
                    CompactNumberField(label: "Weight (lb)", text: $point.weight)
                }
                .padding(.vertical, 2)
            }
            .onDelete { envelope.remove(atOffsets: $0) }
            .onMove { envelope.move(fromOffsets: $0, toOffset: $1) }

            Button {
                Haptics.tap()
                envelope.append(EnvelopeDraft())
            } label: {
                Label("Add envelope point", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("CG envelope")
                Spacer()
                if !envelope.isEmpty { EditButton().font(.subheadline) }
            }
        } footer: {
            Text("Vertices in perimeter order tracing the allowable region.")
        }
    }

    private var previewSection: some View {
        Section("Envelope preview") {
            EnvelopeChart(
                envelope: previewVertices,
                points: [],
                height: 220,
                accessibilitySummary: "Preview of \(previewVertices.count) envelope points."
            )
            .listRowBackground(Color.clear)
        }
    }

    private var validationSection: some View {
        Section {
            ForEach(validationErrors, id: \.self) { err in
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(Brand.danger)
            }
        } header: {
            Text("Fix before saving")
        }
    }

    // MARK: - Load & save

    private func load() {
        guard stations.isEmpty, envelope.isEmpty, tailNumber.isEmpty else { return }
        switch mode {
        case .create(let defaultFuel):
            fuelLbPerGal = trimNum(defaultFuel)
            taxiBurn = "1.4"
        case .edit(let ac):
            tailNumber = ac.tailNumber
            model = ac.model
            emptyWeight = trimNum(ac.emptyWeight)
            emptyArm = trimNum(ac.emptyArm)
            maxRamp = trimNum(ac.maxRampWeight)
            maxTakeoff = trimNum(ac.maxTakeoffWeight)
            maxLanding = trimNum(ac.maxLandingWeight)
            maxZeroFuel = trimNum(ac.maxZeroFuelWeight)
            fuelCapacity = trimNum(ac.fuelCapacityGal)
            usableFuel = trimNum(ac.usableFuelGal)
            fuelArm = trimNum(ac.fuelArm)
            fuelLbPerGal = trimNum(ac.fuelWeightPerGal)
            taxiBurn = trimNum(ac.taxiBurnGal)
            stations = ac.orderedStations.map {
                StationDraft(name: $0.name, arm: trimNum($0.arm),
                             maxWeight: trimNum($0.maxWeight), defaultWeight: trimNum($0.defaultWeight))
            }
            envelope = ac.orderedEnvelope.map {
                EnvelopeDraft(cg: trimNum($0.cgArm), weight: trimNum($0.weight))
            }
        }
    }

    private func save() {
        showValidation = true
        guard canSave else {
            Haptics.warning()
            return
        }

        let ac = existing ?? Aircraft()
        ac.tailNumber = tailNumber.trimmingCharacters(in: .whitespaces)
        ac.model = model.trimmingCharacters(in: .whitespaces)
        ac.emptyWeight = NumParse.nonNegative(emptyWeight)
        ac.emptyArm = NumParse.nonNegative(emptyArm)
        ac.maxRampWeight = NumParse.nonNegative(maxRamp)
        ac.maxTakeoffWeight = NumParse.nonNegative(maxTakeoff)
        ac.maxLandingWeight = NumParse.nonNegative(maxLanding)
        ac.maxZeroFuelWeight = NumParse.nonNegative(maxZeroFuel)
        ac.fuelCapacityGal = NumParse.nonNegative(fuelCapacity)
        ac.usableFuelGal = NumParse.nonNegative(usableFuel)
        ac.fuelArm = NumParse.nonNegative(fuelArm)
        ac.fuelWeightPerGal = NumParse.nonNegative(fuelLbPerGal)
        ac.taxiBurnGal = NumParse.nonNegative(taxiBurn)

        // Replace children. Cascade delete handles the old ones once detached.
        for s in ac.stations { context.delete(s) }
        for e in ac.envelope { context.delete(e) }
        ac.stations = stations.enumerated().map { idx, d in
            Station(name: d.name.trimmingCharacters(in: .whitespaces),
                    arm: NumParse.any(d.arm),
                    maxWeight: NumParse.nonNegative(d.maxWeight),
                    defaultWeight: NumParse.nonNegative(d.defaultWeight),
                    order: idx, aircraft: ac)
        }
        ac.envelope = envelope.enumerated().map { idx, d in
            EnvelopePoint(cgArm: NumParse.any(d.cg),
                          weight: NumParse.nonNegative(d.weight),
                          order: idx, aircraft: ac)
        }

        if existing == nil { context.insert(ac) }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func trimNum(_ value: Double) -> String {
        value == value.rounded() ? String(format: "%.0f", value) : String(format: "%.2f", value)
    }
}

// MARK: - Field helpers

/// A labeled text field that stacks its label above the field.
struct LabeledField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Brand.mono(11, weight: .medium))
                .foregroundStyle(Brand.text3)
            TextField(label, text: $text)
                .keyboardType(keyboard)
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

/// A labeled numeric field, decimal keyboard, mono entry.
struct NumberField: View {
    let label: String
    @Binding var text: String
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(Brand.text)
                .frame(maxWidth: 120)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(text.isEmpty ? "zero" : text)
    }
}

/// A compact stacked numeric field for grid layouts.
struct CompactNumberField: View {
    let label: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Brand.mono(9, weight: .medium))
                .foregroundStyle(Brand.text3)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .font(Brand.mono(14, weight: .medium))
                .foregroundStyle(Brand.text)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Brand.mist3, in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(text.isEmpty ? "zero" : text)
    }
}
