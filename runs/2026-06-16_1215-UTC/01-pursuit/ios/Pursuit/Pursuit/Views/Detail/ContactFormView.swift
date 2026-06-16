import SwiftUI
import SwiftData

struct ContactFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let application: Application
    var existing: Contact?

    @State private var name = ""
    @State private var role: ContactRole = .recruiter
    @State private var email = ""
    @State private var phone = ""
    @State private var linkedIn = ""
    @State private var notes = ""

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name).textInputAutocapitalization(.words)
                    Picker("Role", selection: $role) {
                        ForEach(ContactRole.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                }
                Section("Reach") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("LinkedIn", text: $linkedIn)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "Add Contact" : "Edit Contact")
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
        guard let contact = existing else { return }
        name = contact.name
        role = contact.role
        email = contact.email
        phone = contact.phone
        linkedIn = contact.linkedIn
        notes = contact.notes
    }

    private func save() {
        guard canSave else { return }
        if let contact = existing {
            contact.name = name.trimmingCharacters(in: .whitespaces)
            contact.role = role
            contact.email = email.trimmingCharacters(in: .whitespaces)
            contact.phone = phone
            contact.linkedIn = linkedIn.trimmingCharacters(in: .whitespaces)
            contact.notes = notes
        } else {
            let contact = Contact(
                name: name.trimmingCharacters(in: .whitespaces),
                role: role,
                email: email.trimmingCharacters(in: .whitespaces),
                phone: phone,
                linkedIn: linkedIn.trimmingCharacters(in: .whitespaces),
                notes: notes
            )
            contact.application = application
            context.insert(contact)
            application.contacts.append(contact)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
