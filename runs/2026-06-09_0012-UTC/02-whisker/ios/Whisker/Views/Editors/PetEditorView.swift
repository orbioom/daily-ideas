import SwiftUI
import SwiftData

struct PetEditorView: View {
    var pet: Pet?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var species: Species = .dog
    @State private var breed = ""
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var color: PetColor = .teal
    @State private var notes = ""
    @State private var loaded = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    TextField("Name", text: $name)
                    Picker("Species", selection: $species) {
                        ForEach(Species.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    TextField("Breed (optional)", text: $breed)
                }
                Section("Birthday") {
                    Toggle("Has a known birthday", isOn: $hasBirthday.animation())
                    if hasBirthday {
                        DatePicker("Birthday", selection: $birthday,
                                   in: ...Date(), displayedComponents: .date)
                    }
                }
                Section("Avatar color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(PetColor.allCases) { c in
                            Circle()
                                .fill(c.color)
                                .frame(height: 38)
                                .overlay(Circle().strokeBorder(Brand.text, lineWidth: color == c ? 3 : 0))
                                .onTapGesture { Haptics.selection(); color = c }
                                .accessibilityLabel("\(c.rawValue) color")
                                .accessibilityAddTraits(color == c ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(pet == nil ? "New pet" : "Edit pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let pet, !loaded else { return }
        loaded = true
        name = pet.name; species = pet.species; breed = pet.breed; color = pet.color; notes = pet.notes
        if let b = pet.birthday { hasBirthday = true; birthday = b }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let pet {
            pet.name = trimmed; pet.species = species; pet.breed = breed
            pet.color = color; pet.notes = notes
            pet.birthday = hasBirthday ? birthday : nil
        } else {
            let new = Pet(name: trimmed, species: species, breed: breed,
                          birthday: hasBirthday ? birthday : nil, color: color, notes: notes)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
