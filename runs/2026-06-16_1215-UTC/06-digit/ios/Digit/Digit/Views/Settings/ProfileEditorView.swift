import SwiftUI
import SwiftData

/// Add or edit a child profile. `profile == nil` means create new.
struct ProfileEditorView: View {
    let profile: Profile?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name = ""
    @State private var avatar = "🦊"
    @State private var levelIndex = 0

    private let avatars = ["🦊", "🐼", "🐯", "🦄", "🐢", "🐙", "🦉", "🐳", "🦁", "🐸", "🐝", "🦋"]

    private var isEditing: Bool { profile != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Child's name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Child's name")
                }
                .listRowBackground(Theme.surface)

                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(avatars, id: \.self) { emoji in
                            Button {
                                avatar = emoji
                                Haptics.tap(settings.hapticsEnabled)
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 26))
                                    .frame(width: 46, height: 46)
                                    .background(avatar == emoji ? Theme.accent.opacity(0.18) : Theme.surfaceAlt)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(avatar == emoji ? Theme.accent : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Avatar \(emoji)")
                            .accessibilityAddTraits(avatar == emoji ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)

                Section {
                    Picker("Level", selection: $levelIndex) {
                        ForEach(selectableLevels) { level in
                            Text("\(level.emoji) \(level.title)").tag(level.id)
                        }
                    }
                } header: {
                    Text("Starting level")
                } footer: {
                    Text(settings.isPro ? "All levels available."
                                        : "Multiplication & division levels need Digit Pro.")
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit child" : "New child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .bold))
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var selectableLevels: [Level] {
        settings.isPro ? Curriculum.levels : Curriculum.levels.filter { !$0.requiresPro }
    }

    private func load() {
        if let profile {
            name = profile.name
            avatar = profile.avatarEmoji
            levelIndex = profile.currentLevelIndex
        }
    }

    private func save() {
        let finalName = trimmedName.isEmpty ? "My Child" : trimmedName
        let level = Curriculum.level(at: levelIndex)
        if let profile {
            profile.name = finalName
            profile.avatarEmoji = avatar
            // Editing only changes level/ops if the level actually changed.
            if profile.currentLevelIndex != levelIndex {
                profile.currentLevelIndex = levelIndex
                profile.maxNumber = level.maxNumber
                for op in MathOp.allCases {
                    profile.setOp(op, enabled: level.ops.contains(op))
                }
            }
        } else {
            let newProfile = Profile(name: finalName,
                                     avatarEmoji: avatar,
                                     currentLevelIndex: levelIndex,
                                     maxNumber: level.maxNumber,
                                     enabledOps: Set(level.ops))
            context.insert(newProfile)
            settings.selectedProfileID = newProfile.id.uuidString
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
