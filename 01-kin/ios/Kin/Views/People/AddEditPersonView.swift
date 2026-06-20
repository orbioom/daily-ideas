import SwiftUI
import SwiftData
import PhotosUI

struct AddEditPersonView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let person: Person?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender: Gender = .unknown
    @State private var birthDate: Date = Date()
    @State private var hasBirthDate = false
    @State private var birthPlace = ""
    @State private var deathDate: Date = Date()
    @State private var hasDeathDate = false
    @State private var deathPlace = ""
    @State private var bio = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?

    var isEditing: Bool { person != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First name", text: $firstName)
                        .accessibilityLabel("First name")
                    TextField("Last name", text: $lastName)
                        .accessibilityLabel("Last name")
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    .accessibilityLabel("Gender")
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.badge.plus")
                    }
                    .accessibilityLabel("Choose profile photo")
                }

                Section("Birth") {
                    Toggle("Has Birth Date", isOn: $hasBirthDate)
                        .accessibilityLabel("Has birth date")
                    if hasBirthDate {
                        DatePicker("Date", selection: $birthDate, displayedComponents: .date)
                            .accessibilityLabel("Birth date")
                    }
                    TextField("Birthplace", text: $birthPlace)
                        .accessibilityLabel("Birthplace")
                }

                Section("Death (if applicable)") {
                    Toggle("Has Death Date", isOn: $hasDeathDate)
                        .accessibilityLabel("Has death date")
                    if hasDeathDate {
                        DatePicker("Date", selection: $deathDate, displayedComponents: .date)
                            .accessibilityLabel("Death date")
                    }
                    TextField("Place of death", text: $deathPlace)
                        .accessibilityLabel("Place of death")
                }

                Section("Biography") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Biography")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .accessibilityLabel("Private notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Person" : "New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populateFields() }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            let filename = PhotoStore.shared.newFilename()
                            try? PhotoStore.shared.save(image, filename: filename)
                            if isEditing, let old = person?.photoFilename {
                                PhotoStore.shared.delete(filename: old)
                            }
                            if let p = person {
                                p.photoFilename = filename
                            }
                        }
                    }
                }
            }
        }
    }

    private func populateFields() {
        guard let p = person else { return }
        firstName = p.firstName
        lastName = p.lastName
        gender = p.gender
        if let b = p.birthDate { birthDate = b; hasBirthDate = true }
        birthPlace = p.birthPlace
        if let d = p.deathDate { deathDate = d; hasDeathDate = true }
        deathPlace = p.deathPlace
        bio = p.bio
        notes = p.notes
    }

    private func save() {
        let first = firstName.trimmingCharacters(in: .whitespaces)
        let last = lastName.trimmingCharacters(in: .whitespaces)
        guard !first.isEmpty else { return }

        if let p = person {
            p.firstName = first
            p.lastName = last
            p.gender = gender
            p.birthDate = hasBirthDate ? birthDate : nil
            p.birthPlace = birthPlace
            p.deathDate = hasDeathDate ? deathDate : nil
            p.deathPlace = deathPlace
            p.bio = bio
            p.notes = notes
        } else {
            let p = Person(firstName: first, lastName: last, gender: gender)
            p.birthDate = hasBirthDate ? birthDate : nil
            p.birthPlace = birthPlace
            p.deathDate = hasDeathDate ? deathDate : nil
            p.deathPlace = deathPlace
            p.bio = bio
            p.notes = notes
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}
