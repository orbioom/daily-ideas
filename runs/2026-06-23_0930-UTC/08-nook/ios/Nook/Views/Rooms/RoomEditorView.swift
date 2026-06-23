import SwiftUI
import SwiftData

struct RoomEditorView: View {
    let room: Room?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsRows: [AppSettings]

    @State private var name = ""
    @State private var kind: RoomKind = .livingRoom
    @State private var note = ""
    @State private var didLoad = false
    @State private var showValidation = false

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Room") {
                    TextField("Name (e.g. Main Bathroom)", text: $name)
                        .accessibilityLabel("Room name")
                    if showValidation && trimmed.isEmpty {
                        Text("A name is required.").font(.caption).foregroundStyle(Theme.overdue)
                    }
                    Picker("Type", selection: $kind) {
                        ForEach(RoomKind.allCases) { k in
                            Label(k.label, systemImage: k.systemImage).tag(k)
                        }
                    }
                }
                Section("Notes (optional)") {
                    TextField("Anything to remember about this room", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Room notes")
                }
            }
            .navigationTitle(room == nil ? "New Room" : "Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.font(.body.weight(.semibold)).disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let room {
            name = room.name
            kind = room.kind
            note = room.note
        }
    }

    private func save() {
        guard canSave else { showValidation = true; return }
        if let room {
            room.name = trimmed
            room.kind = kind
            room.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let r = Room(name: trimmed, kind: kind, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
            context.insert(r)
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    RoomEditorView(room: nil)
        .previewModelContainer()
}
