import SwiftUI
import SwiftData

/// Add or edit a measurement. Inputs are in the user's chosen units and stored as SI.
struct AddMeasurementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let child: Child
    var existing: GrowthMeasurement?

    @State private var date = Date()
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var headText = ""
    @State private var note = ""
    @State private var showValidation = false

    private var hasAnyValue: Bool {
        parsed(weightText) != nil || parsed(heightText) != nil || parsed(headText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, in: child.birthDate...Date(), displayedComponents: .date)
                } header: {
                    Text("When")
                } footer: {
                    Text("Age at this date: \(AgeMath.description(from: child.birthDate, to: date)).")
                }

                Section {
                    measureField(.weight, text: $weightText)
                    measureField(.height, text: $heightText)
                    measureField(.head, text: $headText)
                    if showValidation && !hasAnyValue {
                        Label("Enter at least one measurement.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13)).foregroundStyle(Theme.warn)
                    }
                } header: {
                    Text("Measurements")
                } footer: {
                    Text("Values use your unit settings (\(settings.massUnit.short), \(settings.lengthUnit.short)). Leave a field blank to skip it.")
                }

                Section {
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Text("Note")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New measurement" : "Edit measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func measureField(_ measure: GrowthMeasure, text: Binding<String>) -> some View {
        HStack {
            Label(measure.title, systemImage: measure.symbol)
                .foregroundStyle(Theme.ink)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text(settings.unitShort(for: measure))
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 28, alignment: .leading)
        }
    }

    /// Parse a positive decimal from a text field; nil if empty/invalid.
    private func parsed(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty, let v = Double(trimmed), v.isFinite, v > 0 else { return nil }
        return v
    }

    private func si(_ text: String, _ measure: GrowthMeasure) -> Double? {
        guard let display = parsed(text) else { return nil }
        return UnitConvert.toSI(display, measure: measure, mass: settings.massUnit, length: settings.lengthUnit)
    }

    private func loadExisting() {
        guard let m = existing else { return }
        date = m.date
        if let w = m.weightKg {
            weightText = trimmedNumber(UnitConvert.display(w, measure: .weight, mass: settings.massUnit, length: settings.lengthUnit))
        }
        if let h = m.heightCm {
            heightText = trimmedNumber(UnitConvert.display(h, measure: .height, mass: settings.massUnit, length: settings.lengthUnit))
        }
        if let hd = m.headCm {
            headText = trimmedNumber(UnitConvert.display(hd, measure: .head, mass: settings.massUnit, length: settings.lengthUnit))
        }
        note = m.note ?? ""
    }

    private func trimmedNumber(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    private func save() {
        guard hasAnyValue else {
            showValidation = true
            Haptics.warn(settings.hapticsEnabled)
            return
        }
        let w = si(weightText, .weight)
        let h = si(heightText, .height)
        let hd = si(headText, .head)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let m = existing {
            m.date = date
            m.weightKg = w
            m.heightCm = h
            m.headCm = hd
            m.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let m = GrowthMeasurement(date: date,
                                      weightKg: w,
                                      heightCm: h,
                                      headCm: hd,
                                      note: trimmedNote.isEmpty ? nil : trimmedNote,
                                      child: child)
            context.insert(m)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
