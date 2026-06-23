import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query private var settingsList: [AppSettings]

    @State private var showingEditor = false
    @State private var editingProject: Project?
    @State private var showArchived = false

    private var haptics: Bool { settingsList.first?.hapticsEnabled ?? true }

    private var activeProjects: [Project] { projects.filter { !$0.isArchived } }
    private var archivedProjects: [Project] { projects.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.appBackground.ignoresSafeArea()
                if activeProjects.isEmpty && archivedProjects.isEmpty {
                    EmptyStateView(systemImage: "folder.badge.plus",
                                   title: "No projects yet",
                                   message: "Create projects to organize your focus sessions and set daily goals.",
                                   actionTitle: "New project") {
                        editingProject = nil
                        showingEditor = true
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap(haptics)
                        editingProject = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add project")
                }
            }
            .sheet(isPresented: $showingEditor) {
                ProjectEditorView(project: editingProject)
            }
        }
    }

    private var listContent: some View {
        List {
            Section {
                if activeProjects.isEmpty {
                    Text("No active projects.")
                        .foregroundStyle(Theme.Palette.textSecondary)
                } else {
                    ForEach(activeProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectRow(project: project)
                        }
                        .listRowBackground(Theme.Palette.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { delete(project) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button { archive(project) } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(Theme.Palette.textSecondary)
                            Button {
                                editingProject = project
                                showingEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Theme.Palette.brand)
                        }
                    }
                }
            } header: {
                Text("Active")
            }

            if !archivedProjects.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $showArchived) {
                        ForEach(archivedProjects) { project in
                            HStack {
                                ProjectRow(project: project)
                                Spacer()
                                Button("Restore") { unarchive(project) }
                                    .font(.caption.weight(.semibold))
                                    .buttonStyle(.bordered)
                            }
                            .listRowBackground(Theme.Palette.surface)
                            .swipeActions {
                                Button(role: .destructive) { delete(project) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } label: {
                        Text("Archived (\(archivedProjects.count))")
                            .font(.subheadline.weight(.semibold))
                    }
                    .listRowBackground(Theme.Palette.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func archive(_ project: Project) {
        Haptics.tap(haptics)
        project.isArchived = true
        try? context.save()
    }

    private func unarchive(_ project: Project) {
        Haptics.tap(haptics)
        project.isArchived = false
        try? context.save()
    }

    private func delete(_ project: Project) {
        Haptics.warning(haptics)
        context.delete(project)
        try? context.save()
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(project.color.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: project.iconName)
                    .foregroundStyle(project.color)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name), \(subtitle)")
    }

    private var subtitle: String {
        let total = TimeFormat.duration(minutes: project.totalFocusMinutes)
        if project.dailyGoalMinutes > 0 {
            return "\(total) focused · goal \(project.dailyGoalMinutes)m/day"
        }
        return "\(total) focused"
    }
}

#Preview {
    TasksView()
        .modelContainer(for: [Project.self, FocusSession.self, AppSettings.self], inMemory: true)
}
