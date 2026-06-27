import SwiftUI
import SwiftData

struct LogSessionView: View {
    var editing: TrainingSession? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var sparSettings: [SparSettings]

    @State private var sessionType = SessionType.shadowBoxing
    @State private var date = Date()
    @State private var durationMinutes = 45
    @State private var rounds = 0
    @State private var intensity = SessionIntensity.moderate
    @State private var focusAreas = ""
    @State private var notes = ""
    @State private var mood = 3
    @State private var partnerName = ""
    @State private var showValidation = false
    @State private var validationMessage = ""

    private var defaultRound: Int { sparSettings.first?.defaultRoundDurationSeconds ?? 180 }
    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    Picker("Type", selection: $sessionType) {
                        ForEach(SessionType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Duration") {
                    Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 5...240, step: 5)
                    Stepper("Rounds: \(rounds == 0 ? "Free" : "\(rounds)")", value: $rounds, in: 0...20)
                }
                Section("Quality") {
                    Picker("Intensity", selection: $intensity) {
                        ForEach(SessionIntensity.allCases, id: \.self) { i in
                            Text(i.label).tag(i)
                        }
                    }
                    HStack {
                        Text("Mood")
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= mood ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .onTapGesture { mood = star }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Mood: \(mood) out of 5 stars")
                    .accessibilityAdjustableAction { dir in
                        if dir == .increment { mood = min(5, mood + 1) }
                        else { mood = max(1, mood - 1) }
                    }
                }
                Section("Details") {
                    TextField("Focus areas (e.g. Jab-cross, head movement)", text: $focusAreas, axis: .vertical)
                        .lineLimit(1...3)
                    TextField("Training partner (optional)", text: $partnerName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Session" : "Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: { Text(validationMessage) }
        }
        .onAppear { populate() }
    }

    private func populate() {
        guard let s = editing else { return }
        sessionType = s.sessionType
        date = s.date
        durationMinutes = s.durationMinutes
        rounds = s.rounds
        intensity = s.intensity
        focusAreas = s.focusAreas
        notes = s.notes
        mood = s.mood
        partnerName = s.partnerName
    }

    private func save() {
        guard durationMinutes > 0 else {
            validationMessage = "Duration must be greater than 0."
            showValidation = true
            return
        }
        if let s = editing {
            s.sessionTypeRaw = sessionType.rawValue
            s.date = date
            s.durationMinutes = durationMinutes
            s.rounds = rounds
            s.roundDurationSeconds = defaultRound
            s.intensityRaw = intensity.rawValue
            s.focusAreas = focusAreas
            s.notes = notes
            s.mood = mood
            s.partnerName = partnerName
        } else {
            let s = TrainingSession(
                date: date, sessionType: sessionType, durationMinutes: durationMinutes,
                rounds: rounds, roundDurationSeconds: defaultRound,
                intensity: intensity, focusAreas: focusAreas,
                notes: notes, mood: mood, partnerName: partnerName
            )
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}
