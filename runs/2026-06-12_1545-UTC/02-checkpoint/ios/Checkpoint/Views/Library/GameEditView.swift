import SwiftUI
import SwiftData

/// Add a new game (game == nil) or edit an existing one.
struct GameEditView: View {
    let game: Game?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var platform: Platform = .pc
    @State private var genre: Genre = .action
    @State private var status: GameStatus = .backlog
    @State private var priority: Priority = .medium
    @State private var ratingHalf = 0
    @State private var hoursPlayed = ""
    @State private var estimatedHours = ""
    @State private var pricePaid = ""
    @State private var notes = ""

    private var isEditing: Bool { game != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Game") {
                    TextField("Title", text: $title)
                    Picker("Platform", selection: $platform) {
                        ForEach(Platform.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(GameStatus.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { Text($0.label).tag($0) }
                    }
                    HStack {
                        Text("Rating")
                        Spacer()
                        StarRating(ratingHalf: $ratingHalf, size: 22)
                    }
                }
                Section("Time & money") {
                    LabeledField(label: "Hours played", text: $hoursPlayed, suffix: "h")
                    LabeledField(label: "Length to beat", text: $estimatedHours, suffix: "h")
                    LabeledField(label: "Price paid", text: $pricePaid, suffix: Currency.code)
                }
                Section("Notes") {
                    TextField("Anything to remember…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Game" : "New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let g = game else {
            if let def = GameStatus(rawValue: UserDefaults.standard.string(forKey: "defaultStatusRaw") ?? "") {
                status = def
            }
            return
        }
        title = g.title; platform = g.platform; genre = g.genre
        status = g.status; priority = g.priority; ratingHalf = g.ratingHalf
        hoursPlayed = g.hoursPlayed > 0 ? trimmed(g.hoursPlayed) : ""
        estimatedHours = g.estimatedHours > 0 ? trimmed(g.estimatedHours) : ""
        pricePaid = g.pricePaid > 0 ? trimmed(g.pricePaid) : ""
        notes = g.notes
    }

    private func trimmed(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(d)) : String(d)
    }

    private func parse(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let g = game ?? Game(title: trimmedTitle)
        g.title = trimmedTitle
        g.platform = platform
        g.genre = genre
        let wasFinished = g.status.isFinished
        g.status = status
        g.priority = priority
        g.ratingHalf = ratingHalf
        g.hoursPlayed = max(0, parse(hoursPlayed))
        g.estimatedHours = max(0, parse(estimatedHours))
        g.pricePaid = max(0, parse(pricePaid))
        g.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if status == .playing && g.dateStarted == nil { g.dateStarted = Date() }
        if status.isFinished && !wasFinished { g.dateFinished = Date() }
        if game == nil { context.insert(g) }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var suffix: String = ""
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
            if !suffix.isEmpty {
                Text(suffix).foregroundStyle(Theme.textSecondary).font(.caption)
            }
        }
    }
}

struct AddSessionView: View {
    let game: Game
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var hours = ""
    @State private var note = ""

    private var parsedHours: Double {
        Double(hours.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Hours")
                        Spacer()
                        TextField("0", text: $hours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    TextField("Note (optional)", text: $note)
                }
                if game.status == .backlog {
                    Section {
                        Text("Logging time will move this game to Playing.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(parsedHours <= 0)
                }
            }
        }
    }

    private func save() {
        guard parsedHours > 0 else { return }
        let s = PlaySession(date: date, hours: parsedHours, note: note.trimmingCharacters(in: .whitespaces))
        s.game = game
        game.sessions.append(s)
        game.hoursPlayed += parsedHours
        if game.status == .backlog { game.status = .playing }
        if game.dateStarted == nil { game.dateStarted = date }
        context.insert(s)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
