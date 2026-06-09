import SwiftUI
import SwiftData

/// Sheet for logging a new reading or editing an existing one. The metric
/// picker swaps the relevant fields; values are validated and clamped on save.
struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage("cuff.weightUnit") private var weightUnitRaw = WeightUnit.kg.rawValue
    @AppStorage("cuff.glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue

    /// When non-nil, the sheet edits this entry instead of creating one.
    var editing: VitalEntry?

    @State private var kind: VitalKind = .bloodPressure
    @State private var date = Date.now
    @State private var systolic = 120
    @State private var diastolic = 80
    @State private var pulse = 72
    @State private var includePulse = true
    @State private var valueText = ""
    @State private var tag: TimeTag = .from(date: .now)
    @State private var arm: Arm = .left
    @State private var note = ""

    private var weightUnit: WeightUnit { WeightUnit.from(weightUnitRaw) }
    private var glucoseUnit: GlucoseUnit { GlucoseUnit.from(glucoseUnitRaw) }

    private var displayUnitLabel: String {
        switch kind {
        case .weight:  return weightUnit.short
        case .glucose: return glucoseUnit.short
        case .spo2:    return "%"
        case .pulse:   return "bpm"
        case .bloodPressure: return ""
        }
    }

    private var liveCategory: BPCategory {
        BPClassifier.classify(systolic: systolic, diastolic: diastolic)
    }

    private var isValid: Bool {
        switch kind {
        case .bloodPressure:
            return systolic >= 50 && diastolic >= 30 && systolic > diastolic
        default:
            guard let v = Double(valueText.replacingOccurrences(of: ",", with: ".")) else { return false }
            return v > 0
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Metric", selection: $kind) {
                        ForEach(VitalKind.allCases) { Text($0.shortLabel).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(editing != nil)
                }

                if kind == .bloodPressure {
                    bpFields
                } else {
                    valueField
                }

                Section("When") {
                    DatePicker("Date & time", selection: $date)
                    Picker("Time of day", selection: $tag) {
                        ForEach(TimeTag.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Notes") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(editing == nil ? "New reading" : "Edit reading")
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
            .onAppear(perform: loadIfEditing)
            .onChange(of: date) { _, new in
                if editing == nil { tag = .from(date: new) }
            }
        }
    }

    // MARK: - Field groups

    @ViewBuilder private var bpFields: some View {
        Section("Blood pressure") {
            Stepper(value: $systolic, in: 50...260) {
                LabeledContent("Systolic") {
                    Text("\(systolic) mmHg").font(Brand.mono(15, weight: .semibold))
                }
            }
            .accessibilityValue("\(systolic) millimeters of mercury")
            Stepper(value: $diastolic, in: 30...180) {
                LabeledContent("Diastolic") {
                    Text("\(diastolic) mmHg").font(Brand.mono(15, weight: .semibold))
                }
            }
            .accessibilityValue("\(diastolic) millimeters of mercury")

            Toggle("Record pulse", isOn: $includePulse)
            if includePulse {
                Stepper(value: $pulse, in: 30...250) {
                    LabeledContent("Pulse") {
                        Text("\(pulse) bpm").font(Brand.mono(15, weight: .semibold))
                    }
                }
                .accessibilityValue("\(pulse) beats per minute")
            }

            Picker("Arm", selection: $arm) {
                ForEach(Arm.allCases) { Text($0.label).tag($0) }
            }

            HStack {
                Text("Category").foregroundStyle(Brand.text2)
                Spacer()
                BPCategoryBadge(category: liveCategory, compact: true)
            }
            if !isValid {
                Text("Systolic must be above diastolic.")
                    .font(.caption).foregroundStyle(Brand.warn)
            }
        }
    }

    @ViewBuilder private var valueField: some View {
        Section(kind.label) {
            HStack {
                TextField("Value", text: $valueText)
                    .keyboardType(.decimalPad)
                    .font(Brand.mono(17, weight: .semibold))
                Text(displayUnitLabel).foregroundStyle(Brand.text2)
            }
            if !valueText.isEmpty && !isValid {
                Text("Enter a number greater than zero.")
                    .font(.caption).foregroundStyle(Brand.warn)
            }
        }
    }

    // MARK: - Load / Save

    private func loadIfEditing() {
        guard let e = editing else { return }
        kind = e.kind
        date = e.date
        tag = e.tag
        note = e.note
        if e.kind == .bloodPressure {
            systolic = e.systolic
            diastolic = e.diastolic
            pulse = e.pulse > 0 ? e.pulse : 72
            includePulse = e.pulse > 0
            arm = e.arm
        } else {
            valueText = displayString(for: e)
        }
    }

    private func displayString(for e: VitalEntry) -> String {
        switch e.kind {
        case .weight:  return String(format: "%.1f", weightUnit.fromKg(e.value))
        case .glucose: return String(format: glucoseUnit == .mgdl ? "%.0f" : "%.1f", glucoseUnit.fromMgdl(e.value))
        case .spo2, .pulse: return String(format: "%.0f", e.value)
        case .bloodPressure: return ""
        }
    }

    /// Converts the typed display value into canonical storage units.
    private func canonicalValue() -> Double {
        let raw = Double(valueText.replacingOccurrences(of: ",", with: ".")) ?? 0
        switch kind {
        case .weight:  return weightUnit.toKg(raw)
        case .glucose: return glucoseUnit.toMgdl(raw)
        case .spo2:    return min(max(raw, 0), 100)
        case .pulse:   return min(max(raw, 0), 250)
        case .bloodPressure: return 0
        }
    }

    private func save() {
        guard isValid else { return }

        if let e = editing {
            e.date = date
            e.tag = tag
            e.note = note
            if kind == .bloodPressure {
                e.systolic = systolic
                e.diastolic = diastolic
                e.pulse = includePulse ? pulse : 0
                e.arm = arm
            } else {
                e.value = canonicalValue()
            }
            e.clampAll()
        } else {
            let entry: VitalEntry
            if kind == .bloodPressure {
                entry = VitalEntry(date: date, kind: .bloodPressure,
                                   systolic: systolic, diastolic: diastolic,
                                   pulse: includePulse ? pulse : 0,
                                   tag: tag, arm: arm, note: note)
            } else {
                entry = VitalEntry(date: date, kind: kind,
                                   value: canonicalValue(), tag: tag, note: note)
            }
            context.insert(entry)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
