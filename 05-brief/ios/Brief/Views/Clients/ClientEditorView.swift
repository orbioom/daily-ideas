import SwiftUI
import SwiftData

struct ClientEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let client: Client?

    @State private var name = ""
    @State private var company = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var showValidationError = false

    var isEditing: Bool { client != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Required") {
                    TextField("Full Name", text: $name)
                        .accessibilityLabel("Client full name")
                    if showValidationError && name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Name is required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("Company") {
                    TextField("Company Name", text: $company)
                        .accessibilityLabel("Company name")
                }

                Section("Contact") {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Email address")
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .accessibilityLabel("Phone number")
                }

                Section("Address") {
                    TextField("Street, City, State, ZIP", text: $address, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .accessibilityLabel("Address")
                }

                Section("Notes") {
                    TextField("Optional notes about this client", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .accessibilityLabel("Notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Client" : "New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel(isEditing ? "Save changes" : "Add client")
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let client else { return }
        name = client.name
        company = client.company
        email = client.email
        phone = client.phone
        address = client.address
        notes = client.notes
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidationError = true
            return
        }

        if let client {
            client.name = trimmedName
            client.company = company.trimmingCharacters(in: .whitespaces)
            client.email = email.trimmingCharacters(in: .whitespaces)
            client.phone = phone.trimmingCharacters(in: .whitespaces)
            client.address = address.trimmingCharacters(in: .whitespaces)
            client.notes = notes.trimmingCharacters(in: .whitespaces)
        } else {
            let newClient = Client(
                name: trimmedName,
                email: email.trimmingCharacters(in: .whitespaces),
                phone: phone.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                company: company.trimmingCharacters(in: .whitespaces),
                notes: notes.trimmingCharacters(in: .whitespaces)
            )
            modelContext.insert(newClient)
        }

        try? modelContext.save()
        dismiss()
    }
}
