import SwiftUI
import SwiftData

/// Create or edit a recipe. Validates required fields and the base time before
/// allowing a save. Works for both a brand-new recipe (`recipe == nil`) and
/// editing an existing one.
struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// The recipe being edited, or nil to create a new one.
    let recipe: Recipe?

    // Editable fields
    @State private var name = ""
    @State private var filmStock = ""
    @State private var developer = ""
    @State private var dilution = ""
    @State private var boxISO = 400
    @State private var baseMinutes = 8
    @State private var baseSeconds = 0
    @State private var agitationNote = ""
    @State private var stopSec = 60
    @State private var fixSec = 300
    @State private var washSec = 600
    @State private var notes = ""

    @State private var showValidation = false

    private var isEditing: Bool { recipe != nil }

    /// The full base time in seconds from the minute/second pickers.
    private var baseTimeSec: Int { baseMinutes * 60 + baseSeconds }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedFilm: String { filmStock.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedDev: String { developer.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var isValid: Bool {
        !trimmedFilm.isEmpty && !trimmedDev.isEmpty && baseTimeSec >= DevEngine.minDevSec
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Name (optional)", text: $name)
                    TextField("Film stock", text: $filmStock)
                        .textInputAutocapitalization(.words)
                    TextField("Developer", text: $developer)
                        .textInputAutocapitalization(.words)
                    TextField("Dilution (e.g. 1+1)", text: $dilution)
                        .autocorrectionDisabled()
                    Stepper(value: $boxISO, in: 25...12800, step: 25) {
                        InfoRow(label: "Box ISO", value: "\(boxISO)", mono: true)
                    }
                }

                Section {
                    HStack {
                        Text("Base time").foregroundStyle(Brand.text2)
                        Spacer()
                        Text(DevEngine.clock(baseTimeSec))
                            .font(Brand.mono(17, weight: .semibold))
                            .foregroundStyle(Brand.text)
                    }
                    Stepper(value: $baseMinutes, in: 0...60) {
                        InfoRow(label: "Minutes", value: "\(baseMinutes)", mono: true)
                    }
                    Stepper(value: $baseSeconds, in: 0...59, step: 5) {
                        InfoRow(label: "Seconds", value: String(format: "%02d", baseSeconds), mono: true)
                    }
                } header: {
                    Text("Develop time at 20 °C")
                } footer: {
                    Text("Measured at box speed. Latent adjusts this for temperature and push/pull on each run.")
                }

                Section("Agitation") {
                    TextField("Agitation note", text: $agitationNote, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Other phases") {
                    timeStepper(label: "Stop", seconds: $stopSec, step: 15, range: 0...600)
                    timeStepper(label: "Fix", seconds: $fixSec, step: 30, range: 0...1200)
                    timeStepper(label: "Wash", seconds: $washSec, step: 60, range: 0...3600)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...5)
                }

                if showValidation && !isValid {
                    Section {
                        Label("Add a film stock, a developer, and a base time of at least \(DevEngine.minDevSec)s.",
                              systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Brand.warn)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
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

    private func timeStepper(label: String, seconds: Binding<Int>, step: Int, range: ClosedRange<Int>) -> some View {
        Stepper(value: seconds, in: range, step: step) {
            InfoRow(label: label, value: DevEngine.clock(seconds.wrappedValue), mono: true)
        }
    }

    // MARK: - Load / save

    private func load() {
        guard let r = recipe else { return }
        name = r.name
        filmStock = r.filmStock
        developer = r.developer
        dilution = r.dilution
        boxISO = r.boxISO
        baseMinutes = r.baseTimeSec / 60
        baseSeconds = r.baseTimeSec % 60
        agitationNote = r.agitationNote
        stopSec = r.stopSec
        fixSec = r.fixSec
        washSec = r.washSec
        notes = r.notes
    }

    private func save() {
        guard isValid else {
            withAnimation(Brand.ease(0.3)) { showValidation = true }
            Haptics.warning()
            return
        }
        let resolvedName = trimmedName.isEmpty
            ? "\(trimmedFilm) in \(trimmedDev)\(dilution.isEmpty ? "" : " \(dilution)")"
            : trimmedName

        if let r = recipe {
            r.name = resolvedName
            r.filmStock = trimmedFilm
            r.developer = trimmedDev
            r.dilution = dilution.trimmingCharacters(in: .whitespacesAndNewlines)
            r.boxISO = boxISO
            r.baseTimeSec = baseTimeSec
            r.agitationNote = agitationNote
            r.stopSec = stopSec
            r.fixSec = fixSec
            r.washSec = washSec
            r.notes = notes
        } else {
            let r = Recipe(
                name: resolvedName,
                filmStock: trimmedFilm,
                developer: trimmedDev,
                dilution: dilution.trimmingCharacters(in: .whitespacesAndNewlines),
                boxISO: boxISO,
                baseTimeSec: baseTimeSec,
                baseTempC: 20.0,
                agitationNote: agitationNote,
                stopSec: stopSec,
                fixSec: fixSec,
                washSec: washSec,
                notes: notes
            )
            context.insert(r)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
