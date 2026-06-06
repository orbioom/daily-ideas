import SwiftUI
import SwiftData

/// Create or edit a roll's metadata. Validates & trims input; ISO is bounded > 0.
struct RollEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = create a new roll; non-nil = edit existing.
    let roll: Roll?

    @State private var filmStock: String = ""
    @State private var iso: Double = 400
    @State private var format: FilmFormat = .format35mm
    @State private var camera: String = ""
    @State private var notes: String = ""
    @State private var isFinished: Bool = false
    @State private var didLoad = false

    private var isEditing: Bool { roll != nil }

    private var trimmedStock: String {
        filmStock.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !trimmedStock.isEmpty && iso > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Film") {
                    TextField("Film stock", text: $filmStock)
                        .textInputAutocapitalization(.words)
                    Picker("Format", selection: $format) {
                        ForEach(FilmFormat.allCases) { f in
                            Text(f.title).tag(f)
                        }
                    }
                    HStack {
                        Text("ISO")
                        Spacer()
                        Text("\(Int(iso.rounded()))")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: $iso, in: 25...6400, step: 25)
                        .tint(Brand.iso)
                        .accessibilityLabel("ISO")
                        .accessibilityValue("\(Int(iso.rounded()))")
                }

                Section("Gear") {
                    TextField("Camera body", text: $camera)
                        .textInputAutocapitalization(.words)
                }

                Section("Notes") {
                    TextField("Anything about this roll", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if isEditing {
                    Section {
                        Toggle("Developed", isOn: $isFinished)
                    } footer: {
                        Text("Mark a roll developed when you've finished and processed it.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Roll" : "New Roll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        if let roll {
            filmStock = roll.filmStock
            iso = roll.iso
            format = roll.format
            camera = roll.camera
            notes = roll.notes
            isFinished = roll.isFinished
        } else {
            filmStock = settings.defaultFilmStock
            iso = settings.defaultISO
        }
        didLoad = true
    }

    private func save() {
        guard canSave else { return }
        let trimmedCamera = camera.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let roll {
            roll.filmStock = trimmedStock
            roll.iso = max(1, iso)
            roll.format = format
            roll.camera = trimmedCamera
            roll.notes = trimmedNotes
            roll.isFinished = isFinished
        } else {
            let new = Roll(filmStock: trimmedStock, iso: max(1, iso), format: format,
                           camera: trimmedCamera, notes: trimmedNotes)
            context.insert(new)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    RollEditView(roll: nil)
        .environment(SettingsStore())
        .modelContainer(for: [Roll.self, Frame.self], inMemory: true)
}
