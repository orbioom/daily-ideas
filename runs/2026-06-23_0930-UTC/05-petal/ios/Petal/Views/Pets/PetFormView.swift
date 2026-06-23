import SwiftUI
import SwiftData

/// Create or edit a pet profile.
struct PetFormView: View {
    enum Mode { case create, edit(Pet) }

    @Bindable var settings: AppSettings
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var form: PetFormModel
    @State private var showValidation = false

    init(settings: AppSettings, mode: Mode) {
        self.settings = settings
        self.mode = mode
        switch mode {
        case .create: _form = State(initialValue: PetFormModel())
        case .edit(let pet): _form = State(initialValue: PetFormModel(pet: pet))
        }
    }

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PetAvatar(symbol: form.avatarSymbol, tint: form.avatarTint.color, size: 84)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Basics") {
                    TextField("Name", text: $form.name)
                        .accessibilityLabel("Pet name")
                    Picker("Species", selection: Binding(
                        get: { form.species },
                        set: { form.selectSpecies($0) }
                    )) {
                        ForEach(Species.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("Breed (optional)", text: $form.breed)
                }

                Section("Birthday") {
                    Toggle("Has known birthday", isOn: $form.hasBirthday.animation())
                    if form.hasBirthday {
                        DatePicker("Birthday", selection: $form.birthday,
                                   in: ...Date.now, displayedComponents: .date)
                    }
                }

                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(PetFormModel.symbolChoices, id: \.self) { symbol in
                            Button { form.selectSymbol(symbol) } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(form.avatarSymbol == symbol ? Color.white : Theme.primaryText)
                                    .background(
                                        Circle().fill(form.avatarSymbol == symbol ? form.avatarTint.color : Theme.divider.opacity(0.4))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Avatar \(symbol)")
                            .accessibilityAddTraits(form.avatarSymbol == symbol ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)

                    Picker("Color", selection: $form.avatarTint) {
                        ForEach(AvatarTint.allCases) { tint in
                            Text(tint.label).tag(tint)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything to remember…", text: $form.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if showValidation, let msg = form.validationMessage {
                    Section {
                        Label(msg, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.danger)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Pet" : "New Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        guard form.isValid else {
            withAnimation { showValidation = true }
            Haptics.notify(.error, enabled: settings.hapticsEnabled)
            return
        }
        switch mode {
        case .create:
            let pet = form.makePet()
            context.insert(pet)
        case .edit(let pet):
            form.apply(to: pet)
        }
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    PetFormView(settings: AppSettings(hasOnboarded: true), mode: .create)
        .modelContainer(PersistenceController.preview.container)
}
