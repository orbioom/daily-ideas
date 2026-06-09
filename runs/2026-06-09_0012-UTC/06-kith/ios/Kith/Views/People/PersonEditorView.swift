import SwiftUI
import SwiftData

struct PersonEditorView: View {
    var person: Person?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var relationship: Relationship = .friend
    @State private var color: PersonColor = .teal
    @State private var cadence = 0
    @State private var howWeMet = ""
    @State private var notes = ""
    @State private var loaded = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Name", text: $name)
                    Picker("Relationship", selection: $relationship) {
                        ForEach(Relationship.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .onChange(of: relationship) { _, new in
                        if person == nil { cadence = new.defaultCadence }
                    }
                }
                Section("Keep in touch") {
                    Toggle("Remind me to reach out", isOn: Binding(
                        get: { cadence > 0 },
                        set: { cadence = $0 ? (cadence > 0 ? cadence : relationship.defaultCadence == 0 ? 30 : relationship.defaultCadence) : 0 }
                    ))
                    if cadence > 0 {
                        Stepper(value: $cadence, in: 1...365) {
                            Text("Every \(cadence) day\(cadence == 1 ? "" : "s")").font(Brand.mono(14))
                        }
                    }
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(PersonColor.allCases) { c in
                            Circle().fill(c.color).frame(height: 36)
                                .overlay(Circle().strokeBorder(Brand.text, lineWidth: color == c ? 3 : 0))
                                .onTapGesture { Haptics.selection(); color = c }
                                .accessibilityLabel(c.rawValue)
                                .accessibilityAddTraits(color == c ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Context") {
                    TextField("How you met (optional)", text: $howWeMet, axis: .vertical).lineLimit(1...3)
                    TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .navigationTitle(person == nil ? "New person" : "Edit person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let person {
            name = person.name; relationship = person.relationship; color = person.color
            cadence = person.cadenceDays; howWeMet = person.howWeMet; notes = person.notes
        } else {
            cadence = relationship.defaultCadence
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let person {
            person.name = trimmed; person.relationship = relationship; person.color = color
            person.cadenceDays = max(0, cadence); person.howWeMet = howWeMet; person.notes = notes
        } else {
            let new = Person(name: trimmed, relationship: relationship, color: color,
                             cadenceDays: max(0, cadence), howWeMet: howWeMet, notes: notes)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
