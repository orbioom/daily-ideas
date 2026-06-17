import SwiftUI
import SwiftData

/// Add or edit a single entry for one site.
struct EntryEditorView: View {
    let site: MeasurementSite
    let entry: MeasurementEntry?
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var valueText: String = ""
    @State private var date: Date = Date()
    @State private var error: String?

    private var kind: UnitKind { site.unitKind }
    private var unit: String { Units.unitLabel(kind: kind, system: settings.unitSystem) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Value", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(Theme.rounded(20, .semibold))
                            .accessibilityLabel("\(site.name) value in \(unit)")
                        Text(unit)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                } header: {
                    Text(site.name)
                } footer: {
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.bad)
                            .font(.footnote)
                    } else {
                        Text("Enter a value between \(rangeText).")
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(entry == nil ? "Add entry" : "Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var rangeText: String {
        let r = Units.plausibleRange(kind: kind, system: settings.unitSystem)
        return "\(Units.number(r.lowerBound, digits: 0)) and \(Units.number(r.upperBound, digits: 0)) \(unit)"
    }

    private func prefill() {
        if let entry {
            valueText = Units.formatted(canonical: entry.valueCanonical, kind: kind, system: settings.unitSystem)
            date = entry.date
        }
    }

    private func save() {
        let normalized = valueText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let display = Double(normalized) else {
            fail("Please enter a number.")
            return
        }
        guard display > 0 else {
            fail("Value must be positive.")
            return
        }
        let range = Units.plausibleRange(kind: kind, system: settings.unitSystem)
        guard range.contains(display) else {
            fail("That looks out of range. Expected \(rangeText).")
            return
        }
        let canonical = Units.canonicalValue(display: display, kind: kind, system: settings.unitSystem)

        if let entry {
            entry.valueCanonical = canonical
            entry.date = date
        } else {
            let newEntry = MeasurementEntry(siteKey: site.key, valueCanonical: canonical, date: date)
            modelContext.insert(newEntry)
        }
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        onSaved()
        dismiss()
    }

    private func fail(_ message: String) {
        error = message
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}
