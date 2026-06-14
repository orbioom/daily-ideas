import SwiftUI
import SwiftData

/// Add or edit a single play session. When `session` is nil we create a new one.
struct SessionEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let game: Game
    var session: PlaySession?

    @State private var date: Date
    @State private var hoursText: String
    @State private var note: String
    @State private var showValidation = false

    init(game: Game, session: PlaySession? = nil) {
        self.game = game
        self.session = session
        _date = State(initialValue: session?.date ?? .now)
        _hoursText = State(initialValue: session.map { Self.trim($0.hours) } ?? "")
        _note = State(initialValue: session?.note ?? "")
    }

    private var parsedHours: Double? {
        let cleaned = hoursText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 0 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("Hours played")
                        Spacer()
                        TextField("0", text: $hoursText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .accessibilityLabel("Hours played")
                        Text("h").foregroundStyle(Theme.textSecondary)
                    }
                    if showValidation && parsedHours == nil {
                        Label("Enter hours greater than zero.", systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.danger)
                    }
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle(session == nil ? "Log Session" : "Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedHours == nil)
                }
            }
        }
    }

    private func save() {
        guard let hours = parsedHours else {
            showValidation = true
            Haptics.play(.warning, enabled: settings.hapticsEnabled)
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let session {
            session.date = date
            session.hours = hours
            session.note = trimmedNote
        } else {
            let new = PlaySession(date: date, hours: hours, note: trimmedNote)
            modelContext.insert(new)
            // Establishing the relationship via the parent keeps the inverse in sync.
            game.sessions.append(new)
        }
        try? modelContext.save()
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private static func trim(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
