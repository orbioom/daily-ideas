import SwiftUI

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(\.modelContext) private var modelContext
    @State private var showEdit = false
    @State private var newMilestone = ""

    private var sortedMilestones: [Milestone] {
        goal.milestones.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LoftTheme.categoryColor(goal.category).opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: goal.category.icon)
                            .font(.title2)
                            .foregroundStyle(LoftTheme.categoryColor(goal.category))
                    }
                    .accessibilityHidden(true)

                    Text(goal.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)

                    if let date = goal.targetDate {
                        Label(date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    if !goal.milestones.isEmpty {
                        VStack(spacing: 4) {
                            ProgressView(value: goal.progress)
                                .tint(LoftTheme.categoryColor(goal.category))
                            Text("\(Int(goal.progress * 100))% complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Progress: \(Int(goal.progress * 100)) percent")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Notes
            if !goal.notes.isEmpty {
                Section("Notes") {
                    Text(goal.notes)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }

            // Milestones
            Section {
                ForEach(sortedMilestones) { m in
                    HStack(spacing: 12) {
                        Button {
                            m.isCompleted.toggle()
                            m.completedDate = m.isCompleted ? Date() : nil
                            if sortedMilestones.allSatisfy(\.isCompleted) && !goal.milestones.isEmpty {
                                goal.isCompleted = true
                                goal.completedDate = Date()
                            } else if !m.isCompleted {
                                goal.isCompleted = false
                                goal.completedDate = nil
                            }
                        } label: {
                            Image(systemName: m.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(m.isCompleted ? .green : .secondary)
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(m.isCompleted ? "Mark \(m.title) incomplete" : "Complete \(m.title)")

                        Text(m.title)
                            .strikethrough(m.isCompleted)
                            .foregroundStyle(m.isCompleted ? .secondary : .primary)
                    }
                }
                .onDelete { idx in
                    idx.map { sortedMilestones[$0] }.forEach { modelContext.delete($0) }
                }

                // Add milestone input
                HStack {
                    TextField("Add milestone…", text: $newMilestone)
                        .submitLabel(.done)
                        .onSubmit { addMilestone() }
                    if !newMilestone.isEmpty {
                        Button("Add") { addMilestone() }
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            } header: {
                Text("Milestones")
            }

            // Complete / reopen
            Section {
                Button {
                    goal.isCompleted.toggle()
                    goal.completedDate = goal.isCompleted ? Date() : nil
                } label: {
                    Label(goal.isCompleted ? "Reopen Goal" : "Mark as Complete",
                          systemImage: goal.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
                        .foregroundStyle(goal.isCompleted ? .secondary : .green)
                }
            }
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            GoalEditView(goal: goal)
        }
    }

    private func addMilestone() {
        let t = newMilestone.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let m = Milestone(title: t, sortIndex: goal.milestones.count)
        m.goal = goal
        modelContext.insert(m)
        goal.milestones.append(m)
        newMilestone = ""
    }
}
