import SwiftUI
import SwiftData

/// A small sheet to create a new gym or crag. Returns the created location via a
/// callback so the caller (session or climb editor) can select it immediately.
struct LocationEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var onCreate: (Location) -> Void

    @State private var name = ""
    @State private var kind: LocationKind = .gym

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Summit Boulders", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Kind") {
                    Picker("Kind", selection: $kind) {
                        ForEach(LocationKind.allCases) { k in
                            Label(k.title, systemImage: k.symbol).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("New Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard canSave else { return }
        let location = Location(name: trimmedName, kind: kind)
        context.insert(location)
        Haptics.success(enabled: settings.hapticsEnabled)
        onCreate(location)
        dismiss()
    }
}
