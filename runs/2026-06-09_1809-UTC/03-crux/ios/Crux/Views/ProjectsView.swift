import SwiftUI
import SwiftData

/// Projects: areas as collapsible sections, each listing its projects with a
/// progress ring and active-task count. Add areas and projects from here.
struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Area.order) private var areas: [Area]
    @Query(sort: \Project.order) private var allProjects: [Project]

    @State private var showAddArea = false
    @State private var showAddProject = false
    @State private var newName = ""
    @State private var targetAreaID: PersistentIdentifier?

    /// Projects not assigned to any area.
    private var looseProjects: [Project] {
        allProjects.filter { $0.area == nil }.sorted { $0.order < $1.order }
    }

    var body: some View {
        ScrollView {
            if areas.isEmpty && allProjects.isEmpty {
                EmptyStateView(icon: "folder",
                               title: "No projects yet",
                               message: "Create an area like Personal or Work, then add projects to organize your tasks.")
                    .padding(.top, 24)
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(areas) { area in
                        AreaSection(area: area, onAddProject: { beginAddProject(to: area) })
                    }
                    if !looseProjects.isEmpty {
                        looseSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(Brand.pageBackground)
        .navigationDestination(for: Project.self) { ProjectDetailView(project: $0) }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { beginAddArea() } label: { Label("New Area", systemImage: "square.stack.3d.up") }
                    Button { beginAddProject(to: nil) } label: { Label("New Project", systemImage: "folder.badge.plus") }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add area or project")
            }
        }
        .alert("New Area", isPresented: $showAddArea) {
            TextField("Area name", text: $newName)
            Button("Add", action: commitArea)
            Button("Cancel", role: .cancel) { newName = "" }
        }
        .alert("New Project", isPresented: $showAddProject) {
            TextField("Project name", text: $newName)
            Button("Add", action: commitProject)
            Button("Cancel", role: .cancel) { newName = ""; targetAreaID = nil }
        }
    }

    private var looseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "No Area")
            VStack(spacing: 0) {
                ForEach(looseProjects) { project in
                    NavigationLink(value: project) {
                        ProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                    if project.id != looseProjects.last?.id { Divider().background(Brand.hairline) }
                }
            }
            .glassCard(padding: 12)
        }
    }

    // MARK: - Add flows

    private func beginAddArea() { newName = ""; showAddArea = true }
    private func beginAddProject(to area: Area?) {
        newName = ""
        targetAreaID = area?.persistentModelID
        showAddProject = true
    }

    private func commitArea() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (areas.map(\.order).max() ?? -1) + 1
        let area = Area(name: trimmed, colorHex: CruxPalette.color(forIndex: order), order: order)
        context.insert(area)
        TaskActions.save(context)
        newName = ""
        Haptics.success()
    }

    private func commitProject() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let order = (allProjects.map(\.order).max() ?? -1) + 1
        let project = Project(name: trimmed, colorHex: CruxPalette.color(forIndex: order), order: order)
        if let id = targetAreaID, let area = areas.first(where: { $0.persistentModelID == id }) {
            project.area = area
        }
        context.insert(project)
        TaskActions.save(context)
        newName = ""
        targetAreaID = nil
        Haptics.success()
    }
}

// MARK: - Area section

private struct AreaSection: View {
    @Bindable var area: Area
    var onAddProject: () -> Void
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(Brand.ease(0.25)) { expanded.toggle() }
                Haptics.tap()
            } label: {
                HStack(spacing: 10) {
                    Circle().fill(Color(brandHex: area.colorHex)).frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(area.name).font(.headline).foregroundStyle(Brand.text)
                    Spacer()
                    let rollup = area.rollup
                    if rollup.total > 0 {
                        Text("\(rollup.done)/\(rollup.total)")
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(area.name) area")
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")

            if expanded {
                let projects = area.activeProjects
                if projects.isEmpty {
                    Text("No projects yet")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                        .padding(.leading, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(projects) { project in
                            NavigationLink(value: project) {
                                ProjectRow(project: project)
                            }
                            .buttonStyle(.plain)
                            if project.id != projects.last?.id { Divider().background(Brand.hairline) }
                        }
                    }
                    .glassCard(padding: 12)
                }
                Button(action: onAddProject) {
                    Label("Add Project", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.magic)
                }
                .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Project row

struct ProjectRow: View {
    @Bindable var project: Project
    var body: some View {
        HStack(spacing: 12) {
            ProgressRing(fraction: project.progressFraction, tint: Color(brandHex: project.colorHex))
            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                let p = project.progress
                Text(p.total == 0 ? "No tasks" : "\(p.done) of \(p.total) done")
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            let active = project.activeTasks.count
            if active > 0 {
                Text("\(active)")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Brand.text3.opacity(0.12), in: Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Brand.text3)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name), \(project.progress.done) of \(project.progress.total) done")
    }
}
