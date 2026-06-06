import SwiftUI
import SwiftData

/// The projects tab: filterable list of everything on (and off) the needles.
struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]

    @State private var filter: ProjectStatus? = nil
    @State private var newProject: Project?
    @AppStorage("defaultCraft") private var defaultCraftRaw = Craft.knit.rawValue

    private var filtered: [Project] {
        guard let filter else { return projects }
        return projects.filter { $0.status == filter }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if projects.isEmpty {
                        EmptyStateView(icon: "square.stack.3d.up",
                                       title: "No projects yet",
                                       message: "Cast on your first project to start counting rows and tracking gauge.")
                    } else if filtered.isEmpty {
                        EmptyStateView(icon: "line.3.horizontal.decrease.circle",
                                       title: "Nothing here",
                                       message: "No \(filter?.label.lowercased() ?? "") projects. Try another filter.")
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { filterMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { createProject() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New project")
                }
            }
            .navigationDestination(for: Project.self) { ProjectDetailView(project: $0) }
            .sheet(item: $newProject) { proj in
                ProjectEditView(project: proj, isNew: true)
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filter == nil { summaryStrip }
                ForEach(filtered) { project in
                    NavigationLink(value: project) {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var summaryStrip: some View {
        let active = projects.filter { $0.status == .active }.count
        let wips = projects.filter { $0.status == .active || $0.status == .hibernating }.count
        let done = projects.filter { $0.status == .finished }.count
        return HStack(spacing: 10) {
            StatTile(value: "\(active)", label: "Active", tint: Brand.live)
            StatTile(value: "\(wips)", label: "On the go")
            StatTile(value: "\(done)", label: "Finished", tint: Brand.magic)
        }
    }

    private var filterMenu: some View {
        Menu {
            Button { filter = nil } label: { Label("All", systemImage: filter == nil ? "checkmark" : "") }
            ForEach(ProjectStatus.allCases) { s in
                Button { filter = s } label: { Label(s.label, systemImage: filter == s ? "checkmark" : "") }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .accessibilityLabel("Filter projects")
        }
    }

    private func createProject() {
        let p = Project(name: "", craft: Craft(rawValue: defaultCraftRaw) ?? .knit)
        p.counters = [Counter(name: "Rows", value: 0, step: 1, sortIndex: 0)]
        context.insert(p)
        newProject = p
        Haptics.tap()
    }
}

private struct ProjectRow: View {
    let project: Project
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name.isEmpty ? "Untitled project" : project.name)
                        .font(.headline).foregroundStyle(Brand.text)
                    Text("\(project.craft.label) · \(project.yarn.isEmpty ? "No yarn set" : project.yarn)")
                        .font(.subheadline).foregroundStyle(Brand.text2).lineLimit(1)
                }
                Spacer()
                StatusChip(status: project.status)
            }
            if let main = project.orderedCounters.first {
                HStack(spacing: 8) {
                    Image(systemName: "number").font(.caption).foregroundStyle(Brand.text3)
                    Text("\(main.name): ")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    + Text("\(main.value)").font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
                    if project.counters.count > 1 {
                        Text("+\(project.counters.count - 1) more")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                }
            }
        }
        .glassCard()
    }
}
