import SwiftUI
import SwiftData

/// Create or edit a project. Passing `project == nil` creates a new one.
struct ProjectEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [AppSettings]

    let project: Project?

    @State private var name: String = ""
    @State private var colorHex: String = ProjectPalette.hexes.first ?? "7B51B8"
    @State private var iconName: String = "target"
    @State private var hasGoal: Bool = false
    @State private var goalMinutes: Int = 60

    private var haptics: Bool { settingsList.first?.hapticsEnabled ?? true }
    private var isEditing: Bool { project != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Project name", text: $name)
                        .textInputAutocapitalization(.words)
                    if trimmedName.isEmpty {
                        Text("A name is required.")
                            .font(.caption)
                            .foregroundStyle(Theme.Palette.danger)
                    }
                }

                Section("Color") {
                    colorGrid
                }

                Section("Icon") {
                    iconGrid
                }

                Section("Daily goal") {
                    Toggle("Set a daily focus goal", isOn: $hasGoal)
                    if hasGoal {
                        Stepper(value: $goalMinutes, in: 10...480, step: 10) {
                            Text("\(goalMinutes) minutes / day")
                        }
                        .accessibilityValue("\(goalMinutes) minutes per day")
                    }
                }

                Section {
                    previewRow
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(ProjectPalette.hexes, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex) ?? Theme.Palette.brand)
                    .frame(height: 36)
                    .overlay(
                        Circle().stroke(Theme.Palette.textPrimary,
                                        lineWidth: colorHex == hex ? 3 : 0)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .opacity(colorHex == hex ? 1 : 0)
                    )
                    .onTapGesture {
                        Haptics.selection(haptics)
                        colorHex = hex
                    }
                    .accessibilityLabel("Color option")
                    .accessibilityAddTraits(colorHex == hex ? [.isSelected] : [])
            }
        }
        .padding(.vertical, 4)
    }

    private var iconGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(ProjectPalette.icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.title3)
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(iconName == icon ? (Color(hex: colorHex) ?? Theme.Palette.brand) : Theme.Palette.textSecondary)
                    .background(iconName == icon ? (Color(hex: colorHex) ?? Theme.Palette.brand).opacity(0.16) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        Haptics.selection(haptics)
                        iconName = icon
                    }
                    .accessibilityLabel("Icon option")
                    .accessibilityAddTraits(iconName == icon ? [.isSelected] : [])
            }
        }
        .padding(.vertical, 4)
    }

    private var previewRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((Color(hex: colorHex) ?? Theme.Palette.brand).opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .foregroundStyle(Color(hex: colorHex) ?? Theme.Palette.brand)
            }
            Text(trimmedName.isEmpty ? "Project name" : trimmedName)
                .font(.body.weight(.semibold))
                .foregroundStyle(trimmedName.isEmpty ? Theme.Palette.textSecondary : Theme.Palette.textPrimary)
        }
        .accessibilityLabel("Preview")
    }

    private func load() {
        guard let project else { return }
        name = project.name
        colorHex = project.colorHex
        iconName = project.iconName
        hasGoal = project.dailyGoalMinutes > 0
        goalMinutes = project.dailyGoalMinutes > 0 ? project.dailyGoalMinutes : 60
    }

    private func save() {
        guard canSave else { return }
        Haptics.success(haptics)
        let goal = hasGoal ? goalMinutes : 0
        if let project {
            project.name = trimmedName
            project.colorHex = colorHex
            project.iconName = iconName
            project.dailyGoalMinutes = goal
        } else {
            let new = Project(name: trimmedName, colorHex: colorHex, iconName: iconName, dailyGoalMinutes: goal)
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    ProjectEditorView(project: nil)
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
