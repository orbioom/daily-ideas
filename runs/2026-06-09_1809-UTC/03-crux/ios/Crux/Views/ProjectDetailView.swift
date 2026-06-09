import SwiftUI
import SwiftData

/// Project detail: header with progress, the project's active and completed
/// tasks, quick-add, edit, and a mark-complete action.
struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2
    @AppStorage(Prefs.confirmDelete) private var confirmDelete = true

    @State private var quickText = ""
    @State private var editing: TaskItem?
    @State private var showEditProject = false
    @State private var showDeleteConfirm = false

    private var active: [TaskItem] {
        project.tasks.filter { !$0.isDone }.sorted(by: CruxEngine.ordering)
    }
    private var done: [TaskItem] {
        project.tasks.filter { $0.isDone }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private var tint: Color { Color(brandHex: project.colorHex) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                quickAdd

                if active.isEmpty && done.isEmpty {
                    EmptyStateView(icon: "tray",
                                   title: "No tasks yet",
                                   message: "Add the first task to this project above.")
                } else {
                    if !active.isEmpty {
                        taskGroup(title: "To do", tasks: active)
                    }
                    if !done.isEmpty {
                        taskGroup(title: "Completed", tasks: done)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.pageBackground)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditProject = true } label: { Label("Edit Project", systemImage: "pencil") }
                    Button {
                        withAnimation(Brand.ease()) { project.isComplete.toggle() }
                        TaskActions.save(context)
                        Haptics.success()
                    } label: {
                        Label(project.isComplete ? "Mark Active" : "Mark Complete",
                              systemImage: project.isComplete ? "arrow.uturn.backward" : "checkmark.circle")
                    }
                    Button(role: .destructive) {
                        if confirmDelete { showDeleteConfirm = true } else { deleteProject() }
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Project options")
            }
        }
        .sheet(item: $editing) { task in
            TaskEditorView(task: task, isNew: task.title.isEmpty)
        }
        .sheet(isPresented: $showEditProject) {
            ProjectEditorView(project: project)
        }
        .confirmationDialog("Delete \(project.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteProject() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Tasks in this project will be kept but unassigned.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ProgressRing(fraction: project.progressFraction, size: 52, lineWidth: 6, tint: tint)
                VStack(alignment: .leading, spacing: 4) {
                    let p = project.progress
                    Text("\(Int(project.progressFraction * 100))% complete")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Text(p.total == 0 ? "No tasks yet" : "\(p.done) of \(p.total) tasks done")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
            }
            if !project.notes.isEmpty {
                Text(project.notes)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            if project.isComplete {
                Label("Project marked complete", systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Brand.live)
            }
        }
        .glassCard()
    }

    private var quickAdd: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill").foregroundStyle(tint).accessibilityHidden(true)
            TextField("Add a task to \(project.name)", text: $quickText)
                .submitLabel(.done)
                .onSubmit(addQuick)
            if !quickText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add", action: addQuick)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private func taskGroup(title: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(text: title)
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRow(task: task, showProject: false, showDate: true,
                            onToggle: { toggle(task) },
                            onOpen: { editing = task })
                    if task.id != tasks.last?.id { Divider().background(Brand.hairline) }
                }
            }
            .glassCard(padding: 14)
        }
    }

    // MARK: - Actions

    private func addQuick() {
        let trimmed = quickText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let task = TaskItem(title: trimmed)
        task.project = project
        TaskActions.add(task, context: context)
        quickText = ""
        Haptics.success()
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(Brand.ease()) {
            TaskActions.toggleDone(task, context: context, firstWeekday: firstWeekday)
        }
        Haptics.success()
    }

    private func deleteProject() {
        context.delete(project)
        TaskActions.save(context)
        Haptics.warning()
        dismiss()
    }
}
