import SwiftUI
import SwiftData

struct InteractionSheet: View {
    let person: Person
    var interaction: Interaction?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type: InteractionType = .text
    @State private var date = Date()
    @State private var note = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(InteractionType.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section("When") {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                }
                Section("Note") {
                    TextField("What did you talk about?", text: $note, axis: .vertical).lineLimit(2...6)
                }
                if let interaction {
                    Section {
                        Button(role: .destructive) {
                            context.delete(interaction); try? context.save(); dismiss()
                        } label: { Text("Delete interaction") }
                    }
                }
            }
            .navigationTitle(interaction == nil ? "Log with \(person.name)" : "Edit interaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let interaction, !loaded else { return }
        loaded = true
        type = interaction.type; date = interaction.date; note = interaction.note
    }

    private func save() {
        if let interaction {
            interaction.type = type; interaction.date = date; interaction.note = note
        } else {
            let i = Interaction(date: date, type: type, note: note)
            i.person = person
            context.insert(i)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
