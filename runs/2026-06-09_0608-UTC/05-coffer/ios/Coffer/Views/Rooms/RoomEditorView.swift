import SwiftUI
import SwiftData

/// Create or edit a room. When `room` is nil we insert a new one on save.
struct RoomEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.sortIndex, order: .reverse) private var rooms: [Room]

    let room: Room?

    @State private var name = ""
    @State private var iconName = "sofa.fill"
    @State private var notes = ""
    @State private var showingDeleteConfirm = false

    private var isEditing: Bool { room != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Living Room", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Room.iconChoices, id: \.self) { symbol in
                            Button {
                                iconName = symbol
                                Haptics.selection()
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(iconName == symbol ? Color.white : Brand.text2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(iconName == symbol ? Brand.info : Brand.mist3.opacity(0.6))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Icon \(symbol)")
                            .accessibilityAddTraits(iconName == symbol ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete room", systemImage: "trash")
                        }
                    } footer: {
                        Text("Items in this room are kept and moved to Unassigned.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Room" : "New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete this room?",
                                isPresented: $showingDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete room", role: .destructive) { deleteRoom() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The room is removed. Its items move to Unassigned and are not deleted.")
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let room else { return }
        name = room.name
        iconName = room.iconName
        notes = room.notes
    }

    private func save() {
        guard canSave else { return }
        if let room {
            room.name = trimmedName
            room.iconName = iconName
            room.notes = notes
        } else {
            let nextIndex = (rooms.first?.sortIndex ?? -1) + 1
            let new = Room(name: trimmedName, iconName: iconName, notes: notes, sortIndex: nextIndex)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteRoom() {
        guard let room else { return }
        context.delete(room)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
