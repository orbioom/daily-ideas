import SwiftUI
import SwiftData

struct ProfileEditorView: View {
    enum Mode {
        case create
        case edit(Profile)
    }

    let mode: Mode
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var nickname = ""
    @State private var birthdate = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now
    @State private var showValidation = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// At least one usable letter is required for a meaningful chart.
    private var hasUsableLetters: Bool {
        trimmedName.contains { $0.isLetter }
    }

    private var canSave: Bool { !trimmedName.isEmpty && hasUsableLetters }

    /// Live preview of the Life Path so input feels responsive.
    private var previewLifePath: Int {
        NumerologyEngine.lifePath(birthdate: birthdate, config: settings.engineConfig).value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full birth name", text: $fullName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Full birth name")
                    TextField("Nickname (optional)", text: $nickname)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Nickname, optional")
                } header: {
                    Text("Name")
                } footer: {
                    Text("Use the full name given at birth for the most traditional reading.")
                }

                Section("Birthdate") {
                    DatePicker("Born", selection: $birthdate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                if canSave {
                    Section("Preview") {
                        HStack {
                            Text("Life Path")
                                .foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text("\(previewLifePath)")
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Preview Life Path \(previewLifePath)")
                    }
                }

                if showValidation && !canSave {
                    Section {
                        Label("Please enter a name with at least one letter.", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case .edit(let profile) = mode {
            fullName = profile.fullName
            nickname = profile.nickname
            birthdate = profile.birthdate
        }
    }

    private func save() {
        guard canSave else {
            showValidation = true
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        switch mode {
        case .create:
            let profile = Profile(fullName: trimmedName, birthdate: birthdate,
                                  nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines))
            context.insert(profile)
            try? context.save()
            settings.selectedProfileID = profile.persistentModelID.storageIdentifier
        case .edit(let profile):
            profile.fullName = trimmedName
            profile.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.birthdate = birthdate
            try? context.save()
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
