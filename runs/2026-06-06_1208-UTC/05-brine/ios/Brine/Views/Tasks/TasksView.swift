import SwiftUI
import SwiftData

/// Recurring maintenance with due dates and one-tap "done".
struct TasksView: View {
    @Bindable var tank: Tank
    @Environment(\.modelContext) private var context
    @State private var editingTask: CareTask?
    @State private var adding = false

    private var tasks: [CareTask] {
        tank.tasks.sorted { ($0.daysUntilDue ?? Int.max) < ($1.daysUntilDue ?? Int.max) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if tank.tasks.isEmpty {
                        EmptyStateView(icon: "checklist", title: "No tasks yet",
                                       message: "Add recurring jobs like water changes and skimmer cleans.")
                    } else { list }
                }
            }
            .navigationTitle("Care")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $adding) { TaskEditView(task: nil, tank: tank) }
            .sheet(item: $editingTask) { TaskEditView(task: $0, tank: tank) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    taskRow(task)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func taskRow(_ task: CareTask) -> some View {
        HStack(spacing: 14) {
            Button { markDone(task) } label: {
                Image(systemName: task.isOverdue ? "circle" : "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(task.isOverdue ? Brand.text3 : Brand.live)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(task.title) done")
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title).font(.headline).foregroundStyle(Brand.text)
                Text("Every \(task.intervalDays) day\(task.intervalDays == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(dueLabel(task)).font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(task.isOverdue ? Brand.warn : Brand.text2)
                if let last = task.lastDone {
                    Text("did \(last.formatted(.relative(presentation: .named)))")
                        .font(.caption2).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
        .contextMenu {
            Button { editingTask = task } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { delete(task) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func dueLabel(_ t: CareTask) -> String {
        guard let days = t.daysUntilDue else { return "do now" }
        if days < 0 { return "\(-days)d overdue" }
        if days == 0 { return "today" }
        return "in \(days)d"
    }
    private func markDone(_ t: CareTask) { t.lastDone = Date(); try? context.save(); Haptics.success() }
    private func delete(_ t: CareTask) { context.delete(t); try? context.save(); Haptics.warning() }
}

/// Create or edit a recurring care task.
struct TaskEditView: View {
    let task: CareTask?
    let tank: Tank
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var title = ""
    @State private var interval = 7
    @State private var markDoneNow = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    Stepper(value: $interval, in: 1...180) {
                        HStack { Text("Repeat every"); Spacer()
                            Text("\(interval) day\(interval == 1 ? "" : "s")").foregroundStyle(Brand.text2).font(Brand.mono(15)) }
                    }
                }
                if task == nil {
                    Section { Toggle("Mark done today", isOn: $markDoneNow) }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(task == nil ? "New Task" : "Edit Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if let t = task { title = t.title; interval = t.intervalDays }
            }
        }
    }

    private func save() {
        let target = task ?? CareTask(title: "")
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.intervalDays = max(1, interval)
        if task == nil {
            if markDoneNow { target.lastDone = Date() }
            target.tank = tank
            tank.tasks.append(target)
            context.insert(target)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
