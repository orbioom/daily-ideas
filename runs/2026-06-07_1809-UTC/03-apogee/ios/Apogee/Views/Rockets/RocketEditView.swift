import SwiftUI
import SwiftData

/// Create or edit a rocket. Passing `nil` creates a new one; passing an existing
/// rocket edits it in place. Validates the numeric fields and shows a live
/// stability preview as the user types.
struct RocketEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("apogee.defaultCd") private var defaultCd = 0.6

    /// The rocket being edited, or nil when creating.
    let rocket: Rocket?

    @State private var name = ""
    @State private var diameter = ""
    @State private var mass = ""
    @State private var cd = ""
    @State private var cg = ""
    @State private var cp = ""
    @State private var length = ""
    @State private var notes = ""

    private var isEditing: Bool { rocket != nil }

    // MARK: - Parsed values

    private var diameterValue: Double? { positive(diameter) }
    private var massValue: Double? { positive(mass) }
    private var cdValue: Double? { Double(cd.replacingOccurrences(of: ",", with: ".")).flatMap { $0 > 0 ? $0 : nil } }
    private var cgValue: Double? { nonNegative(cg) }
    private var cpValue: Double? { nonNegative(cp) }
    private var lengthValue: Double? { positive(length) }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var isValid: Bool {
        !trimmedName.isEmpty &&
        diameterValue != nil &&
        massValue != nil &&
        cdValue != nil &&
        cgValue != nil &&
        cpValue != nil &&
        lengthValue != nil
    }

    /// Live stability preview from the currently-typed values.
    private var previewCaliber: Double? {
        guard let d = diameterValue, d > 0, let g = cgValue, let p = cpValue else { return nil }
        return (p - g) / d
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Rocket name")
                }

                Section {
                    numberField("Body diameter", value: $diameter, unit: "mm", invalid: diameterValue == nil)
                    numberField("Dry mass (no motor)", value: $mass, unit: "g", invalid: massValue == nil)
                    numberField("Drag coefficient (Cd)", value: $cd, unit: "", invalid: cdValue == nil)
                    numberField("Length", value: $length, unit: "mm", invalid: lengthValue == nil)
                } header: {
                    Text("Airframe")
                } footer: {
                    Text("Diameter is the maximum body-tube diameter — the caliber reference for stability. Drag is typically around 0.6.")
                }

                Section {
                    numberField("CG from nose", value: $cg, unit: "mm", invalid: cgValue == nil)
                    numberField("CP from nose", value: $cp, unit: "mm", invalid: cpValue == nil)
                    if let cal = previewCaliber {
                        let status = StabilityStatus(caliber: cal)
                        HStack {
                            Text("Stability margin").foregroundStyle(Brand.text2)
                            Spacer()
                            Badge(text: "\(Format.calibers(cal)) · \(status.label)", color: status.color)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Stability margin \(Format.calibers(cal)), \(status.label)")
                    }
                } header: {
                    Text("Balance")
                } footer: {
                    Text("Both measured from the nose tip. The CP must sit behind the CG for the rocket to fly straight.")
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Rocket" : "New Rocket")
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
    private func numberField(_ label: String, value: Binding<String>, unit: String, invalid: Bool) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Brand.mono(15, weight: .medium))
                .foregroundStyle(invalid && !value.wrappedValue.isEmpty ? Brand.danger : Brand.text)
                .frame(maxWidth: 110)
                .accessibilityLabel(label)
            if !unit.isEmpty {
                Text(unit).foregroundStyle(Brand.text3).font(.subheadline)
            }
        }
    }

    private func load() {
        guard let r = rocket else {
            cd = trimmed(defaultCd)
            return
        }
        name = r.name
        diameter = trimmed(r.diameterMm)
        mass = trimmed(r.massGramsDry)
        cd = trimmed(r.cd)
        cg = trimmed(r.cgFromNoseMm)
        cp = trimmed(r.cpFromNoseMm)
        length = trimmed(r.lengthMm)
        notes = r.notes
    }

    private func save() {
        guard isValid,
              let d = diameterValue, let m = massValue, let c = cdValue,
              let g = cgValue, let p = cpValue, let l = lengthValue else { return }
        Haptics.success()
        if let r = rocket {
            r.name = trimmedName
            r.diameterMm = d
            r.massGramsDry = m
            r.cd = c
            r.cgFromNoseMm = g
            r.cpFromNoseMm = p
            r.lengthMm = l
            r.notes = notes
        } else {
            let r = Rocket(name: trimmedName, diameterMm: d, massGramsDry: m, cd: c,
                           cgFromNoseMm: g, cpFromNoseMm: p, lengthMm: l, notes: notes)
            context.insert(r)
        }
        try? context.save()
        dismiss()
    }

    // MARK: - Parsing helpers

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
