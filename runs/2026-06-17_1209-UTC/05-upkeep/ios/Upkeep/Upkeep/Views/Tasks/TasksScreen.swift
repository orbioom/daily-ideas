import SwiftUI
import SwiftData

/// All tasks grouped by system, with CRUD and the starter checklist.
struct TasksScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \MaintenanceTask.title) private var allTasks: [MaintenanceTask]

    @State private var showEditor = false
    @State private var paywallReason: PaywallReason?
    @State private var addedNote: String?

    private var activeCount: Int { allTasks.filter { $0.isActive }.count }

    /// Tasks grouped by system, ordered by the system catalog.
    private var grouped: [(system: String, tasks: [MaintenanceTask])] {
        let order = Dictionary(uniqueKeysWithValues: SystemCatalog.all.enumerated().map { ($1.name, $0) })
        let dict = Dictionary(grouping: allTasks) { $0.systemName }
        return dict
            .map { (system: $0.key, tasks: $0.value.sorted { $0.title < $1.title }) }
            .sorted { (order[$0.system] ?? 99) < (order[$1.system] ?? 99) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAddTask()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add task")
                }
                if !allTasks.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                addStarter()
                            } label: {
                                Label("Add starter checklist", systemImage: "checklist")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                TaskEditorView(task: nil)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .overlay(alignment: .bottom) {
                if let addedNote {
                    Text(addedNote)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: addedNote)
        }
    }

    @ViewBuilder
    private var content: some View {
        if allTasks.isEmpty {
            EmptyStateView(symbol: "checklist",
                           title: "No tasks yet",
                           message: "Start with the standard homeowner checklist, or add your own task.",
                           actionTitle: "Add starter checklist") {
                addStarter()
            }
        } else {
            List {
                if !isPro {
                    freeCapBanner
                }
                ForEach(grouped, id: \.system) { group in
                    Section {
                        ForEach(group.tasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                TaskListRow(task: task)
                            }
                        }
                        .onDelete { offsets in
                            delete(in: group.tasks, at: offsets)
                        }
                    } header: {
                        Label(group.system, systemImage: SystemCatalog.symbol(for: group.system))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var freeCapBanner: some View {
        let remaining = Pro.remainingFreeSlots(currentActiveCount: activeCount, isPro: isPro) ?? 0
        return HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(Theme.accent)
            Text("Free plan: \(remaining) of \(Pro.freeActiveTaskLimit) active-task slots left.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Button("Pro") { paywallReason = .taskLimit }
                .font(Theme.rounded(13, .semibold))
        }
        .listRowBackground(Theme.surfaceAlt)
    }

    private func attemptAddTask() {
        if Pro.canAddActiveTask(currentActiveCount: activeCount, isPro: isPro) {
            showEditor = true
        } else {
            paywallReason = .taskLimit
        }
    }

    private func addStarter() {
        let before = allTasks.count
        let added = TaskFactory.addStarterChecklist(into: context)
        Haptics.success(settings.hapticsEnabled)
        let total = before + added
        withAnimation {
            addedNote = added == 0 ? "Checklist already added" : "Added \(added) starter task\(added == 1 ? "" : "s")"
        }
        // Clear the toast after a moment.
        let note = addedNote
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if addedNote == note { withAnimation { addedNote = nil } }
        }
        _ = total
    }

    private func delete(in tasks: [MaintenanceTask], at offsets: IndexSet) {
        for index in offsets where tasks.indices.contains(index) {
            context.delete(tasks[index])
        }
        Haptics.warning(settings.hapticsEnabled)
    }
}

/// Row used inside the Tasks list (no Done button; navigates to detail).
private struct TaskListRow: View {
    let task: MaintenanceTask
    @EnvironmentObject private var settings: AppSettings

    private var dueText: String {
        guard task.isActive else { return "Paused" }
        guard let days = ScheduleEngine.daysUntilDue(for: task, hemisphere: settings.hemisphere) else {
            return "Not scheduled"
        }
        if days < 0 { return "Overdue \(-days)d" }
        if days == 0 { return "Due today" }
        return "Due in \(days)d"
    }

    private var dueColor: Color {
        guard task.isActive else { return Theme.inkFaint }
        let days = ScheduleEngine.daysUntilDue(for: task, hemisphere: settings.hemisphere) ?? Int.max
        if days < 0 { return Theme.bad }
        if days <= settings.clampedDueSoonDays { return Theme.warn }
        return Theme.good
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(task.cadenceType.describe(interval: task.intervalCount, season: task.season))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text(dueText)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(dueColor)
        }
        .padding(.vertical, 2)
    }
}
