import SwiftUI
import SwiftData

/// Create or edit a custom program. Pro-gated by the caller.
struct ProgramBuilderView: View {
    /// nil = creating a new program; non-nil = editing.
    let existing: TrainingProgram?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var allPrograms: [TrainingProgram]

    @State private var name: String = ""
    @State private var level: Int = 2
    @State private var summary: String = ""
    @State private var contract: Int = 4
    @State private var hold: Int = 3
    @State private var relax: Int = 4
    @State private var rest: Int = 25
    @State private var reps: Int = 10
    @State private var sets: Int = 2
    @State private var showValidationError = false

    private var isEditing: Bool { existing != nil }

    /// Live preview of duration/total reps as the user edits.
    private var previewEngine: SessionEngine {
        let draft = TrainingProgram(name: name.isEmpty ? "Preview" : name,
                                    level: level, summary: summary,
                                    contractSeconds: contract, holdSeconds: hold,
                                    relaxSeconds: relax, restSeconds: rest,
                                    reps: reps, sets: sets, isBuiltIn: false, sortIndex: 0)
        return SessionEngine(program: draft)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && (contract + hold + relax) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                phasesSection
                volumeSection
                previewSection
                if showValidationError {
                    Section {
                        Label("Give your program a name and at least one active phase (squeeze, hold, or relax).",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit program" : "New program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Program name", text: $name)
                .accessibilityLabel("Program name")
            Picker("Level", selection: $level) {
                Text("Beginner").tag(1)
                Text("Intermediate").tag(2)
                Text("Advanced").tag(3)
                Text("Expert").tag(4)
            }
            TextField("Short summary (optional)", text: $summary, axis: .vertical)
                .lineLimit(1...3)
                .accessibilityLabel("Summary")
        }
    }

    private var phasesSection: some View {
        Section {
            secondsStepper("Squeeze", value: $contract, range: 0...20, color: Theme.squeeze)
            secondsStepper("Hold", value: $hold, range: 0...30, color: Theme.hold)
            secondsStepper("Relax", value: $relax, range: 0...20, color: Theme.relax)
            secondsStepper("Rest between sets", value: $rest, range: 0...90, color: Theme.rest)
        } header: {
            Text("Phase lengths")
        } footer: {
            Text("Set a phase to 0 seconds to skip it.")
        }
    }

    private var volumeSection: some View {
        Section("Volume") {
            Stepper(value: $reps, in: 1...30) {
                labelRow("Reps per set", "\(reps)")
            }
            .accessibilityValue("\(reps) reps per set")
            Stepper(value: $sets, in: 1...8) {
                labelRow("Sets", "\(sets)")
            }
            .accessibilityValue("\(sets) sets")
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            labelRow("Total reps", "\(previewEngine.totalReps)")
            labelRow("Estimated duration", previewEngine.durationLabel)
        }
    }

    private func secondsStepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, color: Color) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: 10) {
                Circle().fill(color).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)s").foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityValue("\(value.wrappedValue) seconds")
    }

    private func labelRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(Theme.inkSoft)
        }
    }

    private func loadExisting() {
        guard let p = existing else { return }
        name = p.name
        level = max(1, min(4, p.level))
        summary = p.summary
        contract = p.contractSeconds
        hold = p.holdSeconds
        relax = p.relaxSeconds
        rest = p.restSeconds
        reps = p.reps
        sets = p.sets
    }

    private func save() {
        guard isValid else {
            withAnimation { showValidationError = true }
            Haptics.tap(enabled: settings.hapticsEnabled)
            return
        }

        let finalSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryText = finalSummary.isEmpty ? "A custom \(levelName(level).lowercased()) program." : finalSummary

        if let p = existing {
            p.name = trimmedName
            p.level = level
            p.summary = summaryText
            p.contractSeconds = contract
            p.holdSeconds = hold
            p.relaxSeconds = relax
            p.restSeconds = rest
            p.reps = reps
            p.sets = sets
        } else {
            let nextSort = (allPrograms.map { $0.sortIndex }.max() ?? 0) + 1
            let program = TrainingProgram(
                name: trimmedName, level: level, summary: summaryText,
                contractSeconds: contract, holdSeconds: hold, relaxSeconds: relax,
                restSeconds: rest, reps: reps, sets: sets,
                isBuiltIn: false, sortIndex: nextSort
            )
            modelContext.insert(program)
        }
        try? modelContext.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func levelName(_ level: Int) -> String {
        switch level {
        case 1: return "Beginner"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Expert"
        }
    }
}
