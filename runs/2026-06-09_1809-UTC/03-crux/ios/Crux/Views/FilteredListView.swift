import SwiftUI
import SwiftData

/// A filtered task list reached from Browse — either a smart list bucket or a
/// single tag. Reuses TaskRow and the editor.
struct FilteredListView: View {
    let route: BrowseRoute
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2
    @AppStorage(Prefs.confirmDelete) private var confirmDelete = true
    @Query private var tasks: [TaskItem]
    @Query private var tags: [Tag]

    @State private var editing: TaskItem?

    private var resolved: (title: String, tasks: [TaskItem], showDate: Bool, isLog: Bool) {
        switch route {
        case .smart(let list):
            switch list {
            case .anytime:  return ("Anytime", CruxEngine.anytime(tasks), false, false)
            case .someday:  return ("Someday", CruxEngine.someday(tasks), false, false)
            case .logbook:  return ("Logbook", CruxEngine.logbook(tasks), true, true)
            case .today:    return ("Today", CruxEngine.today(tasks), false, false)
            case .overdue:  return ("Overdue", CruxEngine.overdue(tasks), true, false)
            case .upcoming: return ("Upcoming", CruxEngine.upcoming(tasks).flatMap { $0.tasks }, true, false)
            }
        case .tag(let id):
            let tag = tags.first { $0.persistentModelID == id }
            let title = tag.map { "#\($0.name)" } ?? "Tag"
            let filtered = (tag?.tasks ?? []).sorted(by: CruxEngine.ordering)
            return (title, filtered, true, false)
        }
    }

    var body: some View {
        let data = resolved
        ScrollView {
            if data.tasks.isEmpty {
                EmptyStateView(icon: emptyIcon,
                               title: "Nothing here",
                               message: emptyMessage)
                    .padding(.top, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(data.tasks) { task in
                        TaskRow(task: task, showProject: true, showDate: data.showDate,
                                onToggle: { toggle(task) },
                                onOpen: { editing = task })
                        if task.id != data.tasks.last?.id { Divider().background(Brand.hairline) }
                    }
                }
                .glassCard(padding: 14)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)

                if data.isLog {
                    Text("Completed tasks are kept here. Clear them anytime in Settings.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle(data.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { task in
            TaskEditorView(task: task)
        }
    }

    private var emptyIcon: String {
        switch route {
        case .smart(.logbook): return "checkmark.seal"
        case .smart(.someday): return "moon.stars"
        case .tag: return "tag"
        default: return "tray"
        }
    }

    private var emptyMessage: String {
        switch route {
        case .smart(.anytime): return "Tasks with no date and no someday flag will appear here."
        case .smart(.someday): return "Park ideas for later by marking them Someday in the editor."
        case .smart(.logbook): return "Completed tasks will collect here as you finish them."
        case .tag: return "No tasks carry this tag yet."
        default: return "There's nothing in this list right now."
        }
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(Brand.ease()) {
            TaskActions.toggleDone(task, context: context, firstWeekday: firstWeekday)
        }
        Haptics.success()
    }
}
