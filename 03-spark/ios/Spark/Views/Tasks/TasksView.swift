import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FocusTask.sortIndex) private var tasks: [FocusTask]
    @State private var showAdd = false
    @State private var showCompleted = false
    @AppStorage(SparkSettings.defaultDuration) private var defaultDuration = 25

    private var pending: [FocusTask] { tasks.filter { !$0.isCompleted } }
    private var completed: [FocusTask] {
        tasks.filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                if pending.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No Tasks", systemImage: "checklist")
                        } description: {
                            Text("Add tasks to build your focus queue. One will appear on the Focus screen.")
                        } actions: {
                            Button("Add Task") { showAdd = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section("To Focus On (\(pending.count))") {
                        ForEach(pending) { task in
                            NavigationLink(destination: TaskDetailView(task: task)) {
                                TaskRow(task: task)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    task.isCompleted = true
                                    task.completedDate = Date()
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { context.delete(task) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onMove { from, to in
                            var ordered = pending
                            ordered.move(fromOffsets: from, toOffset: to)
                            for (i, t) in ordered.enumerated() { t.sortIndex = i }
                        }
                    }
                }

                if !completed.isEmpty {
                    Section {
                        DisclosureGroup("Completed (\(completed.count))", isExpanded: $showCompleted) {
                            ForEach(completed.prefix(10)) { task in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .accessibilityHidden(true)
                                    Text(task.title)
                                        .strikethrough()
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if let d = task.completedDate {
                                        Text(d.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) { context.delete(task) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        task.isCompleted = false
                                        task.completedDate = nil
                                    } label: {
                                        Label("Undo", systemImage: "arrow.uturn.left")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").accessibilityLabel("Add task")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

struct TaskRow: View {
    let task: FocusTask

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SparkTheme.categoryColor(task.category).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: task.category.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(SparkTheme.categoryColor(task.category))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(task.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(SparkTheme.categoryColor(task.category))
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(task.estimatedMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.category.rawValue), \(task.estimatedMinutes) minutes")
    }
}

struct AddTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FocusTask.sortIndex) private var tasks: [FocusTask]

    @State private var title = ""
    @State private var category: TaskCategory = .work
    @State private var estimatedMinutes = 25
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What do you need to do?", text: $title)
                        .accessibilityLabel("Task title")
                }
                Section("Details") {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    Stepper("Est. time: \(estimatedMinutes) min",
                            value: $estimatedMinutes, in: 5...120, step: 5)
                    .accessibilityLabel("Estimated time: \(estimatedMinutes) minutes")
                }
                Section("Note") {
                    TextField("Optional notes…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let nextIndex = tasks.filter { !$0.isCompleted }.count
        let task = FocusTask(title: t, category: category,
                             estimatedMinutes: estimatedMinutes, sortIndex: nextIndex, note: note)
        context.insert(task)
        dismiss()
    }
}

struct TaskDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: FocusTask
    @State private var showEdit = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Category", value: task.category.rawValue)
                LabeledContent("Estimated", value: "\(task.estimatedMinutes) min")
                LabeledContent("Status", value: task.isCompleted ? "Completed" : "Pending")
                if let d = task.completedDate {
                    LabeledContent("Completed", value: d.formatted(date: .abbreviated, time: .omitted))
                }
            }
            if !task.note.isEmpty {
                Section("Note") {
                    Text(task.note).foregroundStyle(.secondary)
                }
            }
            Section {
                Toggle("Mark as Done", isOn: $task.isCompleted)
                    .tint(.green)
                    .onChange(of: task.isCompleted) { _, new in
                        task.completedDate = new ? Date() : nil
                    }
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditTaskView(task: task)
        }
    }
}

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var task: FocusTask
    @State private var title: String = ""
    @State private var category: TaskCategory = .work
    @State private var estimatedMinutes: Int = 25
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                }
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    Stepper("Est. time: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...120, step: 5)
                }
                Section {
                    TextField("Note", text: $note, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        task.title = t; task.category = category
                        task.estimatedMinutes = estimatedMinutes; task.note = note
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = task.title; category = task.category
                estimatedMinutes = task.estimatedMinutes; note = task.note
            }
        }
    }
}
