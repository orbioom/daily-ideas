import SwiftUI
import SwiftData

/// Create or edit a baby profile. Doubles as the add-baby sheet.
struct BabyEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.activeBabyID) private var activeBabyIDString = ""
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true

    /// Nil when adding a new baby.
    let baby: Baby?

    @State private var name = ""
    @State private var birthDate = Date()
    @State private var colorHex = "3F8F7A"

    private let swatches = ["3F8F7A", "E28E52", "5C86C4", "C07A6E", "C29B3E", "8A6FB0"]

    private var isEditing: Bool { baby != nil }
    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    DatePicker("Birth date", selection: $birthDate,
                               in: ...Date(), displayedComponents: .date)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(swatches, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay(
                                    Circle().strokeBorder(Theme.primaryText(scheme),
                                                          lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    colorHex = hex
                                    Haptics.selection(haptics)
                                }
                                .accessibilityLabel("Color option")
                                .accessibilityAddTraits(colorHex == hex ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if isEditing, let baby {
                    Section {
                        Button(role: .destructive) {
                            deleteBaby(baby)
                        } label: {
                            Label("Delete this profile", systemImage: "trash")
                        }
                    } footer: {
                        Text("Deleting removes all of \(baby.name)'s logs. This can't be undone.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Baby" : "New Baby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let baby {
            name = baby.name
            birthDate = baby.birthDate
            colorHex = baby.colorHex
        }
    }

    private func save() {
        guard !trimmed.isEmpty else { return }
        if let baby {
            baby.name = trimmed
            baby.birthDate = birthDate
            baby.colorHex = colorHex
        } else {
            let new = Baby(name: trimmed, birthDate: birthDate, colorHex: colorHex)
            context.insert(new)
            activeBabyIDString = new.id.uuidString
        }
        try? context.save()
        Haptics.success(haptics)
        dismiss()
    }

    private func deleteBaby(_ baby: Baby) {
        context.delete(baby)
        try? context.save()
        if activeBabyIDString == baby.id.uuidString {
            activeBabyIDString = ""
        }
        Haptics.warning(haptics)
        dismiss()
    }
}
