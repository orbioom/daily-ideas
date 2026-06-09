import SwiftUI
import SwiftData

/// Add or edit a person. When `person` is nil this creates a new one.
struct PersonEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Person.sortIndex) private var allPeople: [Person]

    var person: Person?

    @State private var name = ""
    @State private var relation: Relation = .friend
    @State private var hasBirthday = false
    @State private var birthday = Date.now
    @State private var sizesNote = ""
    @State private var notes = ""

    private var isEditing: Bool { person != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        Form {
            Section("Person") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel("Name")
                Picker("Relation", selection: $relation) {
                    ForEach(Relation.allCases) { r in
                        Label(r.rawValue, systemImage: r.symbol).tag(r)
                    }
                }
            }

            Section("Birthday") {
                Toggle("Has a birthday", isOn: $hasBirthday.animation(Brand.ease(0.2)))
                if hasBirthday {
                    DatePicker("Date", selection: $birthday, displayedComponents: .date)
                }
            }

            Section("Details") {
                TextField("Sizes (clothing, shoes…)", text: $sizesNote, axis: .vertical)
                    .lineLimit(1...3)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(isEditing ? "Edit Person" : "New Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!canSave)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let person else { return }
        name = person.name
        relation = Relation(rawValue: person.relation) ?? .other
        sizesNote = person.sizesNote
        notes = person.notes
        if let b = person.birthday {
            hasBirthday = true
            birthday = b
        }
    }

    private func save() {
        guard canSave else { return }
        let target: Person
        if let person {
            target = person
        } else {
            let nextIndex = (allPeople.map(\.sortIndex).max() ?? -1) + 1
            target = Person(name: trimmedName, sortIndex: nextIndex)
            context.insert(target)
        }
        target.name = trimmedName
        target.relation = relation.rawValue
        target.birthday = hasBirthday ? birthday : nil
        target.sizesNote = sizesNote.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
