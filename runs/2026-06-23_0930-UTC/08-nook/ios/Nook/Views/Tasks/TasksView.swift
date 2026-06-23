import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceTask.nextDue) private var tasks: [MaintenanceTask]
    @Query private var settingsRows: [AppSettings]
    @Query(sort: \Room.name) private var rooms: [Room]

    @State private var searchText = ""
    @State private var filter: TaskFilter = .all
    @State private var showingEditor = false
    @State private var selectedTask: MaintenanceTask?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case overdue = "Overdue"
        case paused = "Paused"
        var id: String { rawValue }
    }

    private var filtered: [MaintenanceTask] {
        tasks.filter { task in
            let matchesSearch = searchText.isEmpty ||
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.room?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (task.appliance?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            guard matchesSearch else { return false }
            switch filter {
            case .all: return true
            case .active: return task.isActive
            case .paused: return !task.isActive
            case .overdue:
                return ScheduleEngine.status(for: task, dueSoonWindow: settings.dueSoonWindowDays) == .overdue
            }
        }
    }

    /// Group either by room or by recurrence depending on the preference.
    private var groups: [(title: String, tasks: [MaintenanceTask])] {
        if settings.groupTasksByRoom {
            let dict = Dictionary(grouping: filtered) { $0.room?.name ?? "Unassigned" }
            return dict.keys.sorted().map { ($0, dict[$0]?.sorted { $0.nextDue < $1.nextDue } ?? []) }
        } else {
            let order = Recurrence.allCases
            return order.compactMap { rec in
                let items = filtered.filter { $0.recurrence == rec }.sorted { $0.nextDue < $1.nextDue }
                return items.isEmpty ? nil : (rec.label, items)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    EmptyStateView(systemImage: "checklist",
                                   title: "No maintenance tasks",
                                   message: "Create your first recurring task, or restore the starter checklist from Settings.",
                                   actionTitle: "Add a task") { showingEditor = true }
                } else if filtered.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass",
                                   title: "Nothing matches",
                                   message: "Try a different search term or filter.")
                } else {
                    list
                }
            }
            .navigationTitle("Tasks")
            .background(Theme.bg.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search tasks, rooms, equipment")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Filter", selection: $filter) {
                            ForEach(TaskFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Filter", systemImage: filter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: {
                        Label("Add task", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(item: $selectedTask) { TaskDetailView(task: $0) }
            .sheet(isPresented: $showingEditor) {
                TaskEditorView(task: nil)
            }
        }
    }

    private var list: some View {
        List {
            if filter != .all {
                Section {
                    Text("Filter: \(filter.rawValue)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            ForEach(groups, id: \.title) { group in
                Section(group.title) {
                    ForEach(group.tasks) { task in
                        Button { selectedTask = task } label: {
                            TaskRow(task: task, dueSoonWindow: settings.dueSoonWindowDays)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.card)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                TaskService.delete(task, context: context)
                                Haptics.warning(enabled: settings.hapticsEnabled)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
    }
}

#Preview {
    TasksView()
        .previewModelContainer()
}
