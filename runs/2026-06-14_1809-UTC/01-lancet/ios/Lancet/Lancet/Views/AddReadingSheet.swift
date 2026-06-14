import SwiftUI
import SwiftData

/// Sheet to log a new reading or edit an existing one.
/// Pass `editing` to edit; omit to create. Value entry respects the unit setting.
struct AddReadingSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// When non-nil, we're editing this reading in place.
    var editing: Reading?

    @State private var valueText: String = ""
    @State private var carbsText: String = ""
    @State private var insulinText: String = ""
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var selectedContext: ReadingContext = .beforeMeal
    @State private var errorMessage: String?

    @FocusState private var valueFocused: Bool

    private var isEditing: Bool { editing != nil }

    /// Parsed canonical mg/dL value, or nil if invalid.
    private var parsedMgdl: Double? {
        let trimmed = valueText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let entered = Double(trimmed) else { return nil }
        let mgdl = settings.unit.mgdl(fromValue: entered)
        guard mgdl > 0, mgdl <= 800 else { return nil }
        return mgdl
    }

    private var canSave: Bool { parsedMgdl != nil }

    var body: some View {
        NavigationStack {
            Form {
                valueSection
                contextSection
                extrasSection
                noteSection
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.high)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit reading" : "Log reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .keyboard) {
                    Spacer()
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { valueFocused = false }
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: Sections

    private var valueSection: some View {
        Section {
            HStack {
                TextField("0", text: $valueText)
                    .keyboardType(settings.unit == .mmol ? .decimalPad : .numberPad)
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(currentBandColor)
                    .focused($valueFocused)
                    .accessibilityLabel("Glucose value")
                    .accessibilityHint("Enter your reading in \(settings.unit.label)")
                Spacer()
                Text(settings.unit.label)
                    .font(Theme.rounded(17, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            if let mgdl = parsedMgdl {
                let band = settings.band(for: mgdl)
                Label(band.rawValue, systemImage: band.symbol)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(band.color)
                    .accessibilityLabel("Classified as \(band.rawValue)")
            }
        } header: {
            Text("Reading")
        } footer: {
            Text("Target range: \(settings.formatRange())")
        }
    }

    private var contextSection: some View {
        Section("When") {
            Picker("Context", selection: $selectedContext) {
                ForEach(ReadingContext.allCases) { ctx in
                    Label(ctx.label, systemImage: ctx.symbol).tag(ctx)
                }
            }
            DatePicker("Date & time", selection: $date, in: ...Date(),
                       displayedComponents: [.date, .hourAndMinute])
        }
    }

    private var extrasSection: some View {
        Section("Optional") {
            HStack {
                Label("Carbs", systemImage: "fork.knife")
                Spacer()
                TextField("0", text: $carbsText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .accessibilityLabel("Carbohydrates in grams")
                Text("g").foregroundStyle(Theme.inkSoft)
            }
            HStack {
                Label("Insulin", systemImage: "syringe")
                Spacer()
                TextField("0", text: $insulinText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .accessibilityLabel("Insulin units")
                Text("U").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField("Anything worth remembering…", text: $note, axis: .vertical)
                .lineLimit(1...4)
                .accessibilityLabel("Note")
        }
    }

    private var currentBandColor: Color {
        if let mgdl = parsedMgdl { return settings.band(for: mgdl).color }
        return Theme.ink
    }

    // MARK: Actions

    private func loadIfEditing() {
        guard let r = editing else { return }
        valueText = settings.formatValue(r.valueMgdl)
        selectedContext = r.context
        date = r.date
        note = r.note
        if let c = r.carbs, c > 0 { carbsText = trimNumber(c) }
        if let ins = r.insulinUnits, ins > 0 { insulinText = trimNumber(ins) }
    }

    private func trimNumber(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func parseOptional(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let v = Double(trimmed), v > 0 else { return nil }
        return v
    }

    private func save() {
        guard let mgdl = parsedMgdl else {
            errorMessage = "Enter a glucose value between 1 and 800 \(settings.unit.label)."
            Haptics.error(settings.hapticsEnabled)
            return
        }
        let carbs = parseOptional(carbsText)
        let insulin = parseOptional(insulinText)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let r = editing {
            r.valueMgdl = mgdl
            r.context = selectedContext
            r.carbs = carbs
            r.insulinUnits = insulin
            r.note = trimmedNote
            r.date = date
        } else {
            let r = Reading(valueMgdl: mgdl,
                            context: selectedContext,
                            carbs: carbs,
                            insulinUnits: insulin,
                            note: trimmedNote,
                            date: date)
            context.insert(r)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
