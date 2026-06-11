import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreate = false
    @State private var filterCat: BoardCategory? = nil

    private var filtered: [Goal] {
        if let cat = filterCat { return goals.filter { $0.category == cat } }
        return goals
    }

    var body: some View {
        List {
            if !goals.isEmpty {
                filterPicker
            }

            let active = filtered.filter { !$0.isCompleted }
            let done = filtered.filter(\.isCompleted)

            if active.isEmpty && done.isEmpty {
                ContentUnavailableView(
                    "No Goals Yet",
                    systemImage: "target",
                    description: Text("Tap + to add your first goal.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !active.isEmpty {
                    Section("Active (\(active.count))") {
                        ForEach(active) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                        .onDelete { idx in
                            idx.map { active[$0] }.forEach { modelContext.delete($0) }
                        }
                    }
                }
                if !done.isEmpty {
                    Section("Completed (\(done.count))") {
                        ForEach(done) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                        .onDelete { idx in
                            idx.map { done[$0] }.forEach { modelContext.delete($0) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add goal")
            }
        }
        .sheet(isPresented: $showCreate) {
            GoalEditView(goal: nil)
        }
    }

    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: filterCat == nil) {
                    filterCat = nil
                }
                ForEach(BoardCategory.allCases, id: \.self) { cat in
                    FilterChip(label: cat.rawValue, isSelected: filterCat == cat) {
                        filterCat = filterCat == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct GoalRowView: View {
    let goal: Goal

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LoftTheme.categoryColor(goal.category).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: goal.category.icon)
                    .foregroundStyle(LoftTheme.categoryColor(goal.category))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .strikethrough(goal.isCompleted)
                HStack(spacing: 6) {
                    if let date = goal.targetDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !goal.milestones.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                        Text("\(goal.milestones.filter(\.isCompleted).count)/\(goal.milestones.count) milestones")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if !goal.milestones.isEmpty {
                ProgressView(value: goal.progress)
                    .tint(LoftTheme.categoryColor(goal.category))
                    .frame(width: 48)
                    .accessibilityLabel("\(Int(goal.progress * 100))% complete")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.title), \(goal.category.rawValue)\(goal.isCompleted ? ", completed" : "")")
    }
}
