import SwiftUI
import SwiftData

struct ChecklistView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChecklistTask.dueDate) private var tasks: [ChecklistTask]

    @State private var showAdd = false
    @State private var editing: ChecklistTask?
    @State private var hideDone = false
    private let cal = Calendar.current

    private var summary: WeddingEngine.ChecklistSummary { WeddingEngine.checklistSummary(tasks) }

    private var open: [ChecklistTask] {
        tasks.filter { !$0.isDone }.sorted { sortKey($0) < sortKey($1) }
    }
    private var done: [ChecklistTask] {
        tasks.filter { $0.isDone }.sorted { ($0.dueDate ?? .distantFuture) > ($1.dueDate ?? .distantFuture) }
    }

    private func sortKey(_ t: ChecklistTask) -> Date { t.dueDate ?? .distantFuture }

    private func isOverdue(_ t: ChecklistTask) -> Bool {
        guard !t.isDone, let due = t.dueDate else { return false }
        return cal.startOfDay(for: due) < cal.startOfDay(for: .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if tasks.isEmpty {
                    EmptyStateView(icon: "checklist",
                                   title: "No tasks yet",
                                   message: "Add to-dos, or start the standard planning checklist from Settings.")
                } else {
                    List {
                        Section { progressRow.listRowBackground(Color.white.opacity(0.001)) }
                        Section("To do") {
                            if open.isEmpty {
                                Text("All done — wonderful! 🎉").font(.subheadline).foregroundStyle(Brand.live)
                                    .listRowBackground(Color.white.opacity(0.001))
                            }
                            ForEach(open) { t in taskRow(t) }
                        }
                        if !hideDone && !done.isEmpty {
                            Section("Completed") {
                                ForEach(done) { t in taskRow(t) }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { withAnimation { hideDone.toggle() } } label: {
                        Image(systemName: hideDone ? "eye.slash" : "eye")
                    }
                    .accessibilityLabel(hideDone ? "Show completed" : "Hide completed")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add task")
                }
            }
            .sheet(isPresented: $showAdd) { TaskEditorView(mode: .create) }
            .sheet(item: $editing) { t in TaskEditorView(mode: .edit(t)) }
        }
    }

    private var progressRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(summary.done) of \(summary.total) complete")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                Spacer()
                if summary.overdue > 0 {
                    Text("\(summary.overdue) overdue").font(.caption).foregroundStyle(Brand.danger)
                }
            }
            ProgressBarLine(fraction: summary.fraction, tint: Color(hex: 0xB07A8C))
        }
        .padding(.vertical, 4)
    }

    private func taskRow(_ t: ChecklistTask) -> some View {
        HStack(spacing: 12) {
            Button {
                t.isDone.toggle()
                if t.isDone { Haptics.success() } else { Haptics.tap() }
                try? context.save()
            } label: {
                Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(t.isDone ? Brand.live : Brand.text3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(t.isDone ? "Mark not done" : "Mark done")

            Button { editing = t } label: {
                HStack {
                    Image(systemName: t.category.icon).foregroundStyle(t.category.color).frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.title).font(.subheadline).foregroundStyle(Brand.text)
                            .strikethrough(t.isDone, color: Brand.text3)
                        if let due = t.dueDate {
                            Text(Format.shortDate.string(from: due))
                                .font(.caption2)
                                .foregroundStyle(isOverdue(t) ? Brand.danger : Brand.text3)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.white.opacity(0.001))
    }
}
