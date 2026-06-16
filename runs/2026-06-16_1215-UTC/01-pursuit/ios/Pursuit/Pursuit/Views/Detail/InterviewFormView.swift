import SwiftUI
import SwiftData

struct InterviewFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let application: Application
    var existing: Interview?

    @State private var roundName = ""
    @State private var hasDate = true
    @State private var scheduledDate = Date()
    @State private var durationMin = 45
    @State private var mode: InterviewMode = .video
    @State private var interviewers = ""
    @State private var prepNotes = ""
    @State private var notes = ""
    @State private var outcome: InterviewOutcome = .pending

    private var canSave: Bool { !roundName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Round") {
                    TextField("Round name (e.g. Coding round)", text: $roundName)
                    Picker("Mode", selection: $mode) {
                        ForEach(InterviewMode.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    Toggle("Scheduled", isOn: $hasDate)
                    if hasDate {
                        DatePicker("When", selection: $scheduledDate)
                    }
                    Stepper("Duration: \(durationMin) min", value: $durationMin, in: 0...480, step: 15)
                }
                Section("Outcome") {
                    Picker("Outcome", selection: $outcome) {
                        ForEach(InterviewOutcome.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("People") {
                    TextField("Interviewers", text: $interviewers)
                }
                Section("Prep") {
                    TextField("Prep notes", text: $prepNotes, axis: .vertical).lineLimit(2...5)
                }
                Section("Notes") {
                    TextField("After-the-fact notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "Add Interview" : "Edit Interview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let interview = existing else { return }
        roundName = interview.roundName
        if let date = interview.scheduledDate { hasDate = true; scheduledDate = date } else { hasDate = false }
        durationMin = interview.durationMin
        mode = interview.mode
        interviewers = interview.interviewers
        prepNotes = interview.prepNotes
        notes = interview.notes
        outcome = interview.outcome
    }

    private func save() {
        guard canSave else { return }
        let date: Date? = hasDate ? scheduledDate : nil
        if let interview = existing {
            interview.roundName = roundName.trimmingCharacters(in: .whitespaces)
            interview.scheduledDate = date
            interview.durationMin = max(0, durationMin)
            interview.mode = mode
            interview.interviewers = interviewers
            interview.prepNotes = prepNotes
            interview.notes = notes
            interview.outcome = outcome
        } else {
            let interview = Interview(
                roundName: roundName.trimmingCharacters(in: .whitespaces),
                scheduledDate: date,
                durationMin: max(0, durationMin),
                mode: mode,
                interviewers: interviewers,
                prepNotes: prepNotes,
                notes: notes,
                outcome: outcome
            )
            interview.application = application
            context.insert(interview)
            application.interviews.append(interview)
            let ev = ActivityEvent(kind: .interviewScheduled, detail: "Added \(interview.roundName) (\(mode.label))")
            ev.application = application
            context.insert(ev)
            application.events.append(ev)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
