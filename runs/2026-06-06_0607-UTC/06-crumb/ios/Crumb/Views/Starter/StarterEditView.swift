import SwiftUI
import SwiftData

/// Edit the starter's identity: name, usual flour, and keeping notes.
struct StarterEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @Bindable var starter: Starter

    @State private var name: String = ""
    @State private var flourType: String = ""
    @State private var notes: String = ""
    @State private var loaded = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Starter") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Usual flour", text: $flourType)
                        .textInputAutocapitalization(.words)
                }
                Section("Notes") {
                    TextField("How you keep it", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Edit Starter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        name = starter.name
        flourType = starter.flourType
        notes = starter.notes
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        starter.name = trimmedName
        let cleanFlour = flourType.trimmingCharacters(in: .whitespacesAndNewlines)
        starter.flourType = cleanFlour.isEmpty ? "Bread flour" : cleanFlour
        starter.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
