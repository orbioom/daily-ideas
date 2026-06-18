import SwiftUI
import SwiftData

/// Edit a single recorded result's value, unit, note and lab.
struct EditResultSheet: View {
    @Bindable var result: LabResult

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var valueText: String = ""
    @State private var unit: String = ""
    @State private var labName: String = ""
    @State private var note: String = ""
    @State private var errorMessage: String?

    private var marker: Biomarker? { result.marker }

    var body: some View {
        NavigationStack {
            Form {
                Section(marker?.name ?? result.markerId) {
                    HStack {
                        TextField("Value", text: $valueText)
                            .keyboardType(.decimalPad)
                        unitField
                    }
                    if let preview = previewStatus {
                        HStack {
                            Text("Status")
                            Spacer()
                            StatusChip(status: preview, compact: true)
                        }
                    }
                }
                Section("Details") {
                    TextField("Lab name", text: $labName)
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Edit Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    @ViewBuilder
    private var unitField: some View {
        if let marker, let alt = marker.altUnit {
            Picker("Unit", selection: $unit) {
                Text(marker.unit).tag(marker.unit)
                Text(alt.unit).tag(alt.unit)
            }
            .pickerStyle(.menu)
        } else {
            Text(unit).foregroundStyle(Theme.inkSoft)
        }
    }

    private var parsedValue: Double? {
        let cleaned = valueText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v.isFinite, v > 0 else { return nil }
        return v
    }

    private var previewStatus: MarkerStatus? {
        guard let marker, let v = parsedValue else { return nil }
        return RangeEngine.assess(marker: marker, rawValue: v, rawUnit: unit, sex: settings.biologicalSex).status
    }

    private func load() {
        valueText = Fmt.value(result.value)
        unit = result.unitRaw
        labName = result.labName
        note = result.note
    }

    private func save() {
        guard let v = parsedValue else {
            errorMessage = "Enter a positive numeric value."
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        result.value = v
        result.unitRaw = unit
        result.labName = labName.trimmingCharacters(in: .whitespacesAndNewlines)
        result.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try context.save()
            Haptics.success(enabled: settings.hapticsEnabled)
            dismiss()
        } catch {
            errorMessage = "Couldn't save changes."
            Haptics.warning(enabled: settings.hapticsEnabled)
        }
    }
}
