import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var room: Room

    @State private var showAddProject = false
    @State private var statusFilter: ProjectStatus?

    var filteredProjects: [Project] {
        let projects = room.projects
        guard let f = statusFilter else { return projects.sorted(by: { $0.createdAt > $1.createdAt }) }
        return projects.filter { $0.status == f }.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        let count = room.projects.filter { $0.status == status }.count
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(ScaffoldTheme.statusColor(status))
                            Text(status.rawValue)
                                .font(.caption2)
                                .foregroundColor(ScaffoldTheme.secondaryLabel)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(status.rawValue): \(count)")
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", selected: statusFilter == nil) { statusFilter = nil }
                        ForEach(ProjectStatus.allCases, id: \.self) { s in
                            filterChip(s.rawValue, selected: statusFilter == s) {
                                statusFilter = statusFilter == s ? nil : s
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowBackground(Color.clear)

            if filteredProjects.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 36))
                            .foregroundColor(ScaffoldTheme.secondaryLabel)
                            .accessibilityHidden(true)
                        Text("No projects")
                            .foregroundColor(ScaffoldTheme.secondaryLabel)
                        Button("Add Project") { showAddProject = true }
                            .font(.subheadline.weight(.medium))
                            .accessibilityLabel("Add project to this room")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                Section("Projects") {
                    ForEach(filteredProjects) { project in
                        NavigationLink(value: project) {
                            ProjectRowView(project: project)
                        }
                    }
                    .onDelete { idx in deleteProjects(at: idx) }
                }
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Project.self) { ProjectDetailView(project: $0) }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddProject = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add project")
            }
        }
        .sheet(isPresented: $showAddProject) {
            AddEditProjectView(project: nil, room: room)
        }
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(selected ? ScaffoldTheme.accent : ScaffoldTheme.secondaryBackground))
                .foregroundColor(selected ? .white : ScaffoldTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }

    private func deleteProjects(at offsets: IndexSet) {
        let sorted = filteredProjects
        for i in offsets {
            context.delete(sorted[i])
        }
        try? context.save()
    }
}
