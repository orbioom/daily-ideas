import SwiftUI
import SwiftData

/// Add or edit a kid profile. `profile == nil` means adding a new one.
struct ProfileEditorView: View {
    let profile: Profile?

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var ageText: String
    @State private var colorHex: Int

    init(profile: Profile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _ageText = State(initialValue: profile?.age.map(String.init) ?? "")
        _colorHex = State(initialValue: profile?.colorHex ?? (AvatarPalette.colors.first ?? 0xFF8A4C))
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var isEditing: Bool { profile != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        AvatarBubble(
                            initial: trimmedName.isEmpty ? "?" : String(trimmedName.uppercased().prefix(1)),
                            color: Color(hex: UInt(colorHex)),
                            size: 96
                        )
                        .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.inkSoft)
                            TextField("e.g. Mia", text: $name)
                                .font(Theme.rounded(20, .semibold))
                                .textInputAutocapitalization(.words)
                                .padding(14)
                                .card(cornerRadius: Theme.radiusSmall)
                                .accessibilityLabel("Name")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age (optional)").font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.inkSoft)
                            TextField("e.g. 4", text: $ageText)
                                .font(Theme.rounded(20, .semibold))
                                .keyboardType(.numberPad)
                                .padding(14)
                                .card(cornerRadius: Theme.radiusSmall)
                                .accessibilityLabel("Age")
                        }

                        ColorPaletteRow(selected: $colorHex)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Kid" : "Add Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(Theme.rounded(17, .bold))
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let age = Int(ageText.trimmingCharacters(in: .whitespaces))
        if let profile {
            profile.name = trimmedName
            profile.age = age
            profile.colorHex = colorHex
        } else {
            let new = Profile(name: trimmedName, colorHex: colorHex, age: age)
            context.insert(new)
            if settings.activeProfileIDString.isEmpty {
                settings.activeProfileIDString = new.id.uuidString
            }
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
