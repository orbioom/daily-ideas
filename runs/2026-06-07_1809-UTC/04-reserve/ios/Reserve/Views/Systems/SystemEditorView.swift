import SwiftUI
import SwiftData

/// Whether the editor sheet is creating a new system or editing an existing one.
enum SystemEditorTarget: Identifiable {
    case new
    case edit(PowerSystem)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let s): return s.id.uuidString
        }
    }
}

/// A form to create or edit a system's battery, solar and inverter parameters.
struct SystemEditorView: View {
    let target: SystemEditorTarget

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PrefKey.defaultChemistry) private var defaultChemistryRaw = Chemistry.lifepo4.rawValue
    @AppStorage(PrefKey.defaultSunHours) private var defaultSunHours = 4.5

    // Working copy of the fields.
    @State private var name = ""
    @State private var batteryCapacityAh = 100.0
    @State private var systemVoltage = 12
    @State private var chemistry: Chemistry = .lifepo4
    @State private var useCustomDoD = false
    @State private var dodOverride = 0.5
    @State private var solarWatts = 0.0
    @State private var peakSunHours = 4.5
    @State private var solarEfficiency = 0.75
    @State private var chargeEfficiency = 0.85
    @State private var hasInverter = false
    @State private var inverterWatts = 2000.0

    @State private var loaded = false

    private let voltages = [12, 24, 48]

    private var isEditing: Bool {
        if case .edit = target { return true }
        return false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && batteryCapacityAh > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                batterySection
                solarSection
                inverterSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit System" : "New System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
            if trimmedName.isEmpty {
                Label("Give the system a name", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(Brand.warn)
            }
        } header: {
            Text("Identity")
        }
    }

    private var batterySection: some View {
        Section {
            stepperRow("Battery capacity", value: $batteryCapacityAh, range: 10...2000, step: 10, unit: "Ah")
            if batteryCapacityAh <= 0 {
                Label("Capacity must be above zero", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Brand.danger)
            }
            Picker("System voltage", selection: $systemVoltage) {
                ForEach(voltages, id: \.self) { Text("\($0) V").tag($0) }
            }
            Picker("Chemistry", selection: $chemistry) {
                ForEach(Chemistry.allCases) { Text($0.label).tag($0) }
            }
            Text(chemistry.blurb)
                .font(.caption)
                .foregroundStyle(Brand.text3)

            Toggle("Custom depth of discharge", isOn: $useCustomDoD)
            if useCustomDoD {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Usable DoD")
                        Spacer()
                        Text(Fmt.percent(dodOverride))
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(Brand.text)
                    }
                    Slider(value: $dodOverride, in: 0.2...1.0, step: 0.05)
                }
            } else {
                InfoRow(label: "Usable DoD (default)", value: Fmt.percent(chemistry.defaultDoD), mono: true)
            }
        } header: {
            Text("Battery bank")
        } footer: {
            Text("Usable energy: \(Fmt.wh(usableWhPreview)) · \(Fmt.ah(usableAhPreview)).")
        }
    }

    private var solarSection: some View {
        Section {
            stepperRow("Solar array", value: $solarWatts, range: 0...4000, step: 50, unit: "W")
            VStack(alignment: .leading) {
                HStack {
                    Text("Peak sun hours")
                    Spacer()
                    Text("\(Fmt.dec1(peakSunHours)) h")
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $peakSunHours, in: 1...8, step: 0.5)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("Solar derate")
                    Spacer()
                    Text(Fmt.percent(solarEfficiency))
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $solarEfficiency, in: 0.4...1.0, step: 0.05)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text("Charge efficiency")
                    Spacer()
                    Text(Fmt.percent(chargeEfficiency))
                        .font(Brand.mono(14, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $chargeEfficiency, in: 0.6...1.0, step: 0.05)
            }
        } header: {
            Text("Solar")
        } footer: {
            Text(solarWatts > 0
                 ? "Estimated harvest: \(Fmt.wh(solarWatts * peakSunHours * solarEfficiency)) per sunny day."
                 : "No solar — set watts above zero to model harvest.")
        }
    }

    private var inverterSection: some View {
        Section {
            Toggle("Has inverter (AC loads)", isOn: $hasInverter)
            if hasInverter {
                stepperRow("Inverter rating", value: $inverterWatts, range: 150...6000, step: 50, unit: "W")
            }
        } header: {
            Text("Inverter")
        } footer: {
            Text("Required only if you run AC appliances through an inverter.")
        }
    }

    // MARK: - Reusable stepper row

    private func stepperRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Fmt.int(value.wrappedValue)) \(unit)")
                    .font(Brand.mono(15, weight: .medium))
                    .foregroundStyle(Brand.text)
            }
        }
    }

    // MARK: - Previews of derived figures

    private var effectiveDoD: Double {
        useCustomDoD ? min(dodOverride, 1.0) : chemistry.defaultDoD
    }
    private var usableWhPreview: Double {
        batteryCapacityAh * Double(systemVoltage) * effectiveDoD
    }
    private var usableAhPreview: Double {
        batteryCapacityAh * effectiveDoD
    }

    // MARK: - Load / Save

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        switch target {
        case .new:
            chemistry = Chemistry(rawValue: defaultChemistryRaw) ?? .lifepo4
            peakSunHours = defaultSunHours
        case .edit(let s):
            name = s.name
            batteryCapacityAh = s.batteryCapacityAh
            systemVoltage = s.systemVoltage
            chemistry = s.chemistry
            useCustomDoD = s.dodOverride > 0
            dodOverride = s.dodOverride > 0 ? s.dodOverride : s.chemistry.defaultDoD
            solarWatts = s.solarWatts
            peakSunHours = s.peakSunHours
            solarEfficiency = s.solarEfficiency
            chargeEfficiency = s.chargeEfficiency
            hasInverter = s.inverterWatts > 0
            inverterWatts = s.inverterWatts > 0 ? s.inverterWatts : 2000
        }
    }

    private func save() {
        guard canSave else { return }
        let dod = useCustomDoD ? min(dodOverride, 1.0) : 0
        let inverter = hasInverter ? inverterWatts : 0

        switch target {
        case .new:
            let system = PowerSystem(
                name: trimmedName,
                batteryCapacityAh: batteryCapacityAh,
                systemVoltage: systemVoltage,
                chemistry: chemistry,
                dodOverride: dod,
                solarWatts: solarWatts,
                peakSunHours: peakSunHours,
                solarEfficiency: solarEfficiency,
                chargeEfficiency: chargeEfficiency,
                inverterWatts: inverter
            )
            context.insert(system)
        case .edit(let s):
            s.name = trimmedName
            s.batteryCapacityAh = batteryCapacityAh
            s.systemVoltage = systemVoltage
            s.chemistry = chemistry
            s.dodOverride = dod
            s.solarWatts = solarWatts
            s.peakSunHours = peakSunHours
            s.solarEfficiency = solarEfficiency
            s.chargeEfficiency = chargeEfficiency
            s.inverterWatts = inverter
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
