import SwiftUI
import SwiftData

/// Editor for a routine's name, time-of-day, icon, color, and ordered steps.
/// Edits happen on a value-type draft so Cancel discards cleanly; Save commits to SwiftData.
struct RoutineEditorView: View {
    let target: RoutineEditorTarget

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var draft: RoutineDraft
    @State private var editingStep: StepDraft?
    @State private var addingStep = false

    private let isNew: Bool
    private let sortOrder: Int

    init(target: RoutineEditorTarget) {
        self.target = target
        switch target {
        case .create(let next):
            _draft = State(initialValue: RoutineDraft())
            isNew = true
            sortOrder = next
        case .edit(let routine):
            _draft = State(initialValue: RoutineDraft(routine: routine))
            isNew = false
            sortOrder = routine.sortOrder
        }
    }

    private let iconChoices = ["sunrise.fill", "moon.stars.fill", "brain.head.profile", "figure.run",
                               "house.fill", "cup.and.saucer.fill", "book.fill", "drop.fill",
                               "leaf.fill", "heart.fill", "bolt.fill", "sparkles"]
    private let colorChoices: [String] = ["C77E22", "9B6BD0", "2E8B7A", "C0492F", "5E72C8", "3E8E5A"]

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                appearanceSection
                stepsSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isNew ? "New Routine" : "Edit Routine")
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
            .sheet(isPresented: $addingStep) {
                StepEditorView(step: StepDraft()) { newStep in
                    draft.steps.append(newStep)
                }
            }
            .sheet(item: $editingStep) { step in
                StepEditorView(step: step) { updated in
                    if let idx = draft.steps.firstIndex(where: { $0.id == updated.id }) {
                        draft.steps[idx] = updated
                    }
                }
            }
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section {
            TextField("Routine name", text: $draft.name)
                .font(Theme.rounded(17))
            Picker("Time of day", selection: $draft.timeOfDay) {
                ForEach(TimeOfDay.allCases) { tod in
                    Label(tod.label, systemImage: tod.symbol).tag(tod)
                }
            }
        } header: {
            Text("Details")
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Icon").font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(iconChoices, id: \.self) { icon in
                        Button {
                            draft.iconName = icon
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(draft.iconName == icon ? Theme.onAccent : Theme.ink)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(draft.iconName == icon ? Theme.accent : Theme.surfaceAlt))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Icon \(icon)")
                        .accessibilityAddTraits(draft.iconName == icon ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Color").font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                HStack(spacing: 14) {
                    ForEach(colorChoices, id: \.self) { hex in
                        Button {
                            draft.colorHex = hex
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            Circle()
                                .fill(Color(hex: parseHex(hex)))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(Theme.ink, lineWidth: draft.colorHex == hex ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Color option")
                        .accessibilityAddTraits(draft.colorHex == hex ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Appearance")
        }
        .listRowBackground(Theme.surface)
    }

    private var stepsSection: some View {
        Section {
            if draft.steps.isEmpty {
                Text("No steps yet. Add a timed step or a checkbox.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(draft.steps) { step in
                    Button { editingStep = step } label: { stepRow(step) }
                        .buttonStyle(.plain)
                }
                .onMove(perform: moveSteps)
                .onDelete(perform: deleteSteps)
            }

            Button { addingStep = true } label: {
                Label("Add step", systemImage: "plus.circle.fill")
                    .foregroundStyle(Theme.accent)
            }
        } header: {
            HStack {
                Text("Steps")
                Spacer()
                if draft.steps.count > 1 {
                    EditButton()
                        .font(Theme.rounded(13, .semibold))
                        .textCase(nil)
                }
            }
        } footer: {
            Text("Timed steps count down automatically; checkbox steps wait for a tap. Tap Edit to reorder, swipe to delete.")
        }
        .listRowBackground(Theme.surface)
    }

    private func stepRow(_ step: StepDraft) -> some View {
        HStack(spacing: 12) {
            Image(systemName: step.iconName)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title.isEmpty ? "Untitled step" : step.title)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                Text(step.kind == .timed ? "Timed · \(TimeFormat.clock(step.durationSec))" : "Check off")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: step.kind.symbol)
                .foregroundStyle(Theme.inkFaint)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
    }

    // MARK: Mutations

    private func moveSteps(_ offsets: IndexSet, _ destination: Int) {
        draft.steps.move(fromOffsets: offsets, toOffset: destination)
    }

    private func deleteSteps(_ offsets: IndexSet) {
        draft.steps.remove(atOffsets: offsets)
    }

    private func save() {
        let trimmed = draft.name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch target {
        case .edit(let routine):
            apply(draft, to: routine)
        case .create:
            let routine = Routine(name: trimmed,
                                  timeOfDay: draft.timeOfDay,
                                  colorHex: draft.colorHex,
                                  iconName: draft.iconName,
                                  sortOrder: sortOrder)
            context.insert(routine)
            apply(draft, to: routine)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    /// Commit the draft onto a real Routine, replacing its steps in order.
    private func apply(_ draft: RoutineDraft, to routine: Routine) {
        routine.name = draft.name.trimmingCharacters(in: .whitespaces)
        routine.timeOfDay = draft.timeOfDay
        routine.colorHex = draft.colorHex
        routine.iconName = draft.iconName

        // Remove existing steps (cascade-safe) then rebuild from the draft order.
        for existing in routine.steps {
            context.delete(existing)
        }
        routine.steps.removeAll()
        for (i, sd) in draft.steps.enumerated() {
            let step = RoutineStep(title: sd.title.trimmingCharacters(in: .whitespaces),
                                   iconName: sd.iconName,
                                   kind: sd.kind,
                                   durationSec: max(0, sd.durationSec),
                                   note: sd.note,
                                   sortOrder: i)
            step.routine = routine
            routine.steps.append(step)
        }
    }
}
