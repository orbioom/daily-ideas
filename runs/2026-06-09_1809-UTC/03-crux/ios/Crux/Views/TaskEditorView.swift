import SwiftUI
import SwiftData

/// Full task editor presented as a sheet. Edits a live `TaskItem` via @Bindable;
/// all changes persist on Save. Supports clearing dates, recurrence interval,
/// project/tag pickers, and full subtask CRUD with reordering.
struct TaskEditorView: View {
    @Bindable var task: TaskItem
    /// When true, the task was newly created for this sheet and is deleted on
    /// cancel (so cancelling a "+" doesn't leave an empty task behind).
    var isNew: Bool = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.confirmDelete) private var confirmDelete = true
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2

    @Query(sort: \Project.order) private var allProjects: [Project]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    // Local mirrors for clearable date pickers.
    @State private var hasScheduled = false
    @State private var scheduled = Date()
    @State private var hasDue = false
    @State private var due = Date()
    @State private var newSubtask = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                datesSection
                organizeSection
                subtasksSection
                if !isNew { deleteSection }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(task.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: syncFromTask)
            .confirmationDialog("Delete this task?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section {
            TextField("Task title", text: $task.title, axis: .vertical)
                .font(.body.weight(.medium))
            TextField("Notes", text: $task.notes, axis: .vertical)
                .lineLimit(2...6)
                .foregroundStyle(Brand.text2)
        }
    }

    private var datesSection: some View {
        Section("When") {
            Toggle(isOn: $hasScheduled.animation(Brand.ease(0.25))) {
                Label("Scheduled", systemImage: "calendar")
            }
            if hasScheduled {
                DatePicker("Date", selection: $scheduled, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
            }

            Toggle(isOn: $hasDue.animation(Brand.ease(0.25))) {
                Label("Due date", systemImage: "flag.checkered")
            }
            if hasDue {
                DatePicker("Due", selection: $due, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
            }

            Toggle(isOn: $task.isSomeday) {
                Label("Someday", systemImage: "moon.stars")
            }

            Picker(selection: priorityBinding) {
                ForEach(Priority.allCases) { p in
                    Label(p.label, systemImage: p.symbol).tag(p)
                }
            } label: {
                Label("Priority", systemImage: "flag")
            }

            Picker(selection: recurrenceBinding) {
                ForEach(Recurrence.allCases) { r in
                    Text(r.label).tag(r)
                }
            } label: {
                Label("Repeat", systemImage: "repeat")
            }

            if task.recurrence == .everyN {
                Stepper(value: intervalBinding, in: 1...365) {
                    Text("Every \(max(1, task.recurrenceInterval)) day\(task.recurrenceInterval == 1 ? "" : "s")")
                }
            }
        }
    }

    private var organizeSection: some View {
        Section("Organize") {
            Picker(selection: projectBinding) {
                Text("None").tag(Project?.none)
                ForEach(allProjects.filter { !$0.isComplete }) { project in
                    Text(project.name).tag(Project?.some(project))
                }
            } label: {
                Label("Project", systemImage: "folder")
            }

            if allTags.isEmpty {
                Text("No tags yet — create them in Browse.")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tags", systemImage: "tag")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    FlowLayout(spacing: 8) {
                        ForEach(allTags) { tag in
                            SelectChip(text: tag.name, isSelected: task.tags.contains(where: { $0.id == tag.id })) {
                                toggleTag(tag)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var subtasksSection: some View {
        Section("Checklist") {
            ForEach(orderedSubtasks) { sub in
                HStack(spacing: 10) {
                    CheckCircle(isDone: sub.isDone, tint: Brand.magic) {
                        sub.isDone.toggle()
                        Haptics.selection()
                    }
                    Text(sub.title)
                        .strikethrough(sub.isDone, color: Brand.text3)
                        .foregroundStyle(sub.isDone ? Brand.text3 : Brand.text)
                }
            }
            .onDelete(perform: deleteSubtasks)
            .onMove(perform: moveSubtasks)

            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                TextField("Add subtask", text: $newSubtask)
                    .onSubmit(addSubtask)
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                if confirmDelete { showDeleteConfirm = true } else { performDelete() }
            } label: {
                Label("Delete Task", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Bindings

    private var priorityBinding: Binding<Priority> {
        Binding(get: { task.priority }, set: { task.priority = $0 })
    }
    private var recurrenceBinding: Binding<Recurrence> {
        Binding(get: { task.recurrence }, set: { task.recurrence = $0 })
    }
    private var intervalBinding: Binding<Int> {
        Binding(get: { max(1, task.recurrenceInterval) }, set: { task.recurrenceInterval = max(1, $0) })
    }
    private var projectBinding: Binding<Project?> {
        Binding(get: { task.project }, set: { task.project = $0 })
    }

    private var orderedSubtasks: [Subtask] {
        task.subtasks.sorted { $0.order < $1.order }
    }

    // MARK: - Actions

    private func syncFromTask() {
        if let s = task.scheduledDate { hasScheduled = true; scheduled = s }
        if let d = task.dueDate { hasDue = true; due = d }
    }

    private func toggleTag(_ tag: Tag) {
        Haptics.selection()
        if let idx = task.tags.firstIndex(where: { $0.id == tag.id }) {
            task.tags.remove(at: idx)
        } else {
            task.tags.append(tag)
        }
    }

    private func addSubtask() {
        let trimmed = newSubtask.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (task.subtasks.map(\.order).max() ?? -1) + 1
        let sub = Subtask(title: trimmed, order: order)
        sub.task = task
        context.insert(sub)
        task.subtasks.append(sub)
        newSubtask = ""
        Haptics.tap()
    }

    private func deleteSubtasks(at offsets: IndexSet) {
        let ordered = orderedSubtasks
        for index in offsets {
            guard ordered.indices.contains(index) else { continue }
            let sub = ordered[index]
            if let i = task.subtasks.firstIndex(where: { $0.id == sub.id }) {
                task.subtasks.remove(at: i)
            }
            context.delete(sub)
        }
    }

    private func moveSubtasks(from source: IndexSet, to destination: Int) {
        var ordered = orderedSubtasks
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, sub) in ordered.enumerated() { sub.order = i }
    }

    private func save() {
        task.title = task.title.trimmingCharacters(in: .whitespaces)
        task.scheduledDate = hasScheduled ? scheduled : nil
        task.dueDate = hasDue ? due : nil
        if task.recurrence == .everyN { task.recurrenceInterval = max(1, task.recurrenceInterval) }
        TaskActions.save(context)
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        if isNew {
            context.delete(task)
            TaskActions.save(context)
        }
        dismiss()
    }

    private func performDelete() {
        context.delete(task)
        TaskActions.save(context)
        Haptics.warning()
        dismiss()
    }
}
