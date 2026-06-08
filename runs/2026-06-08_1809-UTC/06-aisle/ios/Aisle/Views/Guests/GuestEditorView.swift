import SwiftUI
import SwiftData

struct GuestEditorView: View {
    enum Mode { case create, edit(Guest) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SeatingTable.name) private var tables: [SeatingTable]

    @State private var name = ""
    @State private var side: WeddingSide = .both
    @State private var rsvp: RSVP = .pending
    @State private var partySize = 1
    @State private var meal: MealChoice = .none
    @State private var notes = ""
    @State private var tableID: PersistentIdentifier?

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name or party (e.g. The Smiths)", text: $name)
                    Stepper("Party size: \(partySize)", value: $partySize, in: 1...20)
                    Picker("Side", selection: $side) {
                        ForEach(WeddingSide.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("RSVP") {
                    Picker("Status", selection: $rsvp) {
                        ForEach(RSVP.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Meal", selection: $meal) {
                        ForEach(MealChoice.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("Seating") {
                    Picker("Table", selection: $tableID) {
                        Text("Unassigned").tag(PersistentIdentifier?.none)
                        ForEach(tables) { t in
                            Text(t.name).tag(t.persistentModelID as PersistentIdentifier?)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Allergies, plus-ones, anything…", text: $notes, axis: .vertical).lineLimit(1...4)
                }
                if case let .edit(g) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(g); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Remove guest", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Guest" : "Add Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(g) = mode {
            name = g.name; side = g.side; rsvp = g.rsvp
            partySize = g.partySize; meal = g.meal; notes = g.notes
            tableID = g.table?.persistentModelID
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let table = tables.first { $0.persistentModelID == tableID }
        switch mode {
        case .create:
            let g = Guest(name: trimmed, side: side, rsvp: rsvp, partySize: partySize, meal: meal, notes: notes)
            g.table = table
            context.insert(g)
        case .edit(let g):
            g.name = trimmed; g.side = side; g.rsvp = rsvp
            g.partySize = partySize; g.meal = meal; g.notes = notes
            g.table = table
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
