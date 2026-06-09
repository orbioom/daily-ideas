import SwiftUI
import SwiftData

/// Creates a new custom challenge or edits an existing custom one. Built-in
/// challenges are not editable here. Edits are committed to SwiftData on Save.
struct ChallengeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("mettle.defaultHardMode") private var defaultHardMode = false

    /// nil = create a new challenge.
    let challenge: Challenge?

    @State private var name = ""
    @State private var summary = ""
    @State private var durationDays = 30
    @State private var hardMode = false
    @State private var drafts: [TaskDraft] = []
    @State private var loaded = false

    private var isEditing: Bool { challenge != nil }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !drafts.isEmpty
            && drafts.allSatisfy { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        Form {
            Section("Challenge") {
                TextField("Name", text: $name)
                    .accessibilityLabel("Challenge name")
                TextField("Summary (optional)", text: $summary, axis: .vertical)
                    .lineLimit(1...3)
                Stepper(value: $durationDays, in: 1...365) {
                    LabeledContent("Duration", value: "\(durationDays) days")
                }
                .accessibilityValue("\(durationDays) days")
                Toggle("Hard mode", isOn: $hardMode)
                    .accessibilityHint("Missing a required task resets the run to Day 1")
            }

            Section {
                ForEach($drafts) { $draft in
                    TaskDraftRow(draft: $draft)
                }
                .onDelete { drafts.remove(atOffsets: $0) }

                Button {
                    drafts.append(TaskDraft())
                    Haptics.tap()
                } label: {
                    Label("Add task", systemImage: "plus.circle")
                }
            } header: {
                Text("Daily tasks")
            } footer: {
                Text("Each task must be done every day. Set a target value to make a task measured (e.g. 128 oz water); leave it 0 for a simple checkbox.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(isEditing ? "Edit Challenge" : "New Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let c = challenge {
            name = c.name
            summary = c.summary
            durationDays = c.durationDays
            hardMode = c.hardMode
            drafts = c.orderedTasks.map { t in
                TaskDraft(title: t.title, detail: t.detail, iconName: t.iconName,
                          target: t.targetValue, unit: t.unit)
            }
        } else {
            hardMode = defaultHardMode
            drafts = [TaskDraft(title: "", detail: "", iconName: "checkmark.circle", target: 0, unit: "")]
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !drafts.isEmpty else { return }

        let target: Challenge
        if let existing = challenge {
            target = existing
            target.name = trimmedName
            target.summary = summary
            target.durationDays = min(max(durationDays, 1), 365)
            target.hardMode = hardMode
            // Replace tasks wholesale for simplicity and correctness.
            for t in target.tasks { context.delete(t) }
        } else {
            target = Challenge(name: trimmedName, summary: summary,
                               durationDays: durationDays, isBuiltIn: false,
                               hardMode: hardMode, sortIndex: 1000)
            context.insert(target)
        }

        for (order, draft) in drafts.enumerated() {
            let title = draft.title.trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            let t = ChallengeTask(title: title,
                                  detail: draft.detail,
                                  iconName: draft.iconName,
                                  targetValue: max(0, draft.target),
                                  unit: draft.target > 0 ? draft.unit : "",
                                  order: order)
            t.challenge = target
            context.insert(t)
        }

        try? context.save()
        Haptics.success()
        dismiss()
    }
}

/// A transient, value-type draft for one task row in the editor.
struct TaskDraft: Identifiable {
    let id = UUID()
    var title: String = ""
    var detail: String = ""
    var iconName: String = "checkmark.circle"
    var target: Double = 0
    var unit: String = ""
}

private struct TaskDraftRow: View {
    @Binding var draft: TaskDraft

    private static let iconChoices = [
        "checkmark.circle", "figure.run", "figure.walk", "figure.strengthtraining.traditional",
        "drop.fill", "book.fill", "leaf.fill", "fork.knife", "camera.fill",
        "bed.double.fill", "moon.zzz.fill", "heart.fill", "flame.fill", "timer"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: draft.iconName)
                    .foregroundStyle(Brand.magic)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                TextField("Task title", text: $draft.title)
                    .accessibilityLabel("Task title")
            }
            TextField("Detail (optional)", text: $draft.detail)
                .font(.caption)
                .foregroundStyle(Brand.text2)
                .accessibilityLabel("Task detail")

            Picker("Icon", selection: $draft.iconName) {
                ForEach(Self.iconChoices, id: \.self) { icon in
                    Image(systemName: icon).tag(icon)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Target")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Spacer()
                TextField("0", value: $draft.target, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .accessibilityLabel("Target value")
                TextField("unit", text: $draft.unit)
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
                    .disabled(draft.target <= 0)
                    .foregroundStyle(draft.target > 0 ? Brand.text : Brand.text3)
                    .accessibilityLabel("Unit")
            }
        }
        .padding(.vertical, 4)
    }
}
