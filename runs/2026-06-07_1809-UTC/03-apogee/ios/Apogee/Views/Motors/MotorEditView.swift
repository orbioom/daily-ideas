import SwiftUI
import SwiftData

/// Create or edit a custom motor. Catalog motors are never edited here — only
/// records created by the user (`isCustom == true`).
struct MotorEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let motor: Motor?

    @State private var designation = ""
    @State private var manufacturer = ""
    @State private var totalImpulse = ""
    @State private var avgThrust = ""
    @State private var burnTime = ""
    @State private var propMass = ""
    @State private var totalMass = ""
    @State private var diameter = "24"
    @State private var delays = ""

    private var isEditing: Bool { motor != nil }

    private var trimmedDesignation: String { designation.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedManufacturer: String { manufacturer.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var impulseValue: Double? { positive(totalImpulse) }
    private var thrustValue: Double? { positive(avgThrust) }
    private var burnValue: Double? { positive(burnTime) }
    private var propValue: Double? { nonNegative(propMass) }
    private var totalMassValue: Double? { positive(totalMass) }
    private var diameterValue: Double? { positive(diameter) }

    private var isValid: Bool {
        !trimmedDesignation.isEmpty &&
        impulseValue != nil &&
        thrustValue != nil &&
        burnValue != nil &&
        propValue != nil &&
        totalMassValue != nil &&
        diameterValue != nil
    }

    private var derivedClass: String? {
        guard let i = impulseValue else { return nil }
        let temp = Motor(totalImpulseNs: i)
        return temp.impulseClass
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Designation (e.g. F32)", text: $designation)
                        .accessibilityLabel("Motor designation")
                    TextField("Manufacturer", text: $manufacturer)
                        .accessibilityLabel("Manufacturer")
                }

                Section {
                    field("Total impulse", value: $totalImpulse, unit: "N·s", invalid: impulseValue == nil)
                    field("Avg thrust", value: $avgThrust, unit: "N", invalid: thrustValue == nil)
                    field("Burn time", value: $burnTime, unit: "s", invalid: burnValue == nil)
                    if let cls = derivedClass {
                        HStack {
                            Text("Impulse class").foregroundStyle(Brand.text2)
                            Spacer()
                            Badge(text: cls, color: Brand.info)
                        }
                    }
                } header: {
                    Text("Performance")
                }

                Section {
                    field("Propellant mass", value: $propMass, unit: "g", invalid: propValue == nil)
                    field("Total mass", value: $totalMass, unit: "g", invalid: totalMassValue == nil)
                    field("Casing diameter", value: $diameter, unit: "mm", invalid: diameterValue == nil)
                } header: {
                    Text("Physical")
                }

                Section {
                    TextField("e.g. 4,7,10", text: $delays)
                        .keyboardType(.numbersAndPunctuation)
                        .font(Brand.mono(15))
                        .accessibilityLabel("Ejection delays, comma separated")
                } header: {
                    Text("Ejection delays")
                } footer: {
                    Text("Comma-separated seconds. Leave blank for a plugged / no-delay motor.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Motor" : "Custom Motor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    @ViewBuilder
    private func field(_ label: String, value: Binding<String>, unit: String, invalid: Bool) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(invalid && !value.wrappedValue.isEmpty ? Brand.danger : Brand.text)
                .frame(maxWidth: 100)
                .accessibilityLabel(label)
            Text(unit).foregroundStyle(Brand.text3).font(.subheadline)
        }
    }

    private func load() {
        guard let m = motor else { return }
        designation = m.designation
        manufacturer = m.manufacturer
        totalImpulse = trimmed(m.totalImpulseNs)
        avgThrust = trimmed(m.avgThrustN)
        burnTime = trimmed(m.burnTimeS)
        propMass = trimmed(m.propMassG)
        totalMass = trimmed(m.totalMassG)
        diameter = trimmed(m.diameterMm)
        delays = m.delaysCSV
    }

    private func save() {
        guard isValid,
              let i = impulseValue, let th = thrustValue, let b = burnValue,
              let pm = propValue, let tm = totalMassValue, let d = diameterValue else { return }
        Haptics.success()
        let cleanDelays = delays
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            .map { Format.number($0, decimals: 0) }
            .joined(separator: ",")
        if let m = motor {
            m.designation = trimmedDesignation
            m.manufacturer = trimmedManufacturer.isEmpty ? "Custom" : trimmedManufacturer
            m.totalImpulseNs = i
            m.avgThrustN = th
            m.burnTimeS = b
            m.propMassG = pm
            m.totalMassG = tm
            m.diameterMm = d
            m.delaysCSV = cleanDelays
        } else {
            let m = Motor(designation: trimmedDesignation,
                          manufacturer: trimmedManufacturer.isEmpty ? "Custom" : trimmedManufacturer,
                          totalImpulseNs: i, avgThrustN: th, burnTimeS: b,
                          propMassG: pm, totalMassG: tm, diameterMm: d,
                          delaysCSV: cleanDelays, isCustom: true)
            context.insert(m)
        }
        try? context.save()
        dismiss()
    }

    private func positive(_ s: String) -> Double? {
        guard let v = Double(s.replacingOccurrences(of: ",", with: ".")), v > 0 else { return nil }
        return v
    }
    private func nonNegative(_ s: String) -> Double? {
        guard let v = Double(s.replacingOccurrences(of: ",", with: ".")), v >= 0 else { return nil }
        return v
    }
    private func trimmed(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }
}
