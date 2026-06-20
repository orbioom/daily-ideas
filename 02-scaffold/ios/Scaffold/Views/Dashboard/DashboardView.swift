import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var properties: [Property]
    @Query(filter: #Predicate<Project> { $0.status != ProjectStatus.complete },
           sort: \Project.createdAt, order: .reverse)
    private var activeProjects: [Project]

    @Query(filter: #Predicate<Material> { !$0.purchased })
    private var unpurchasedMaterials: [Material]

    @State private var showAddRoom = false
    @State private var selectedProject: Project?

    private var property: Property? { properties.first }
    private var overdueProjects: [Project] {
        let now = Date()
        return activeProjects.filter { p in
            guard let target = p.targetDate else { return false }
            return target < now
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let prop = property {
                        propertyHeader(prop)
                    }

                    if !overdueProjects.isEmpty {
                        overdueSection
                    }

                    activeProjectsSection

                    if !unpurchasedMaterials.isEmpty {
                        shoppingSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Project.self) { proj in
                ProjectDetailView(project: proj)
            }
        }
    }

    private func propertyHeader(_ property: Property) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(ScaffoldTheme.accent)
                    .accessibilityHidden(true)
                Text(property.name)
                    .font(.headline)
                    .foregroundColor(ScaffoldTheme.label)
                Spacer()
            }
            let total = property.rooms.flatMap { $0.projects }.reduce(0) { $0 + $1.actualCost }
            HStack(spacing: 24) {
                quickStat("\(property.rooms.count)", "Rooms")
                quickStat("\(activeProjects.count)", "Active")
                quickStat(String(format: "$%.0f", total), "Spent")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ScaffoldTheme.accent.opacity(0.12))
        )
        .accessibilityElement(children: .contain)
    }

    private func quickStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(ScaffoldTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Overdue Projects", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)

            ForEach(overdueProjects.prefix(3)) { project in
                NavigationLink(value: project) {
                    ProjectRowView(project: project)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.red.opacity(0.2), lineWidth: 1))
        )
        .accessibilityElement(children: .contain)
    }

    private var activeProjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Projects")
                .font(.headline)
                .foregroundColor(ScaffoldTheme.label)

            if activeProjects.isEmpty {
                emptyActiveState
            } else {
                ForEach(activeProjects.prefix(5)) { project in
                    NavigationLink(value: project) {
                        ProjectRowView(project: project)
                    }
                }
            }
        }
    }

    private var emptyActiveState: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer")
                .font(.system(size: 36))
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .accessibilityHidden(true)
            Text("No active projects")
                .font(.subheadline)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
            Text("Head to a room to start a new project.")
                .font(.caption)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(ScaffoldTheme.secondaryBackground))
        .accessibilityLabel("No active projects")
    }

    private var shoppingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Buy Soon (\(unpurchasedMaterials.count) items)", systemImage: "cart.fill")
                .font(.headline)
                .foregroundColor(ScaffoldTheme.label)

            ForEach(unpurchasedMaterials.prefix(4)) { mat in
                HStack {
                    Text(mat.name)
                        .font(.subheadline)
                        .foregroundColor(ScaffoldTheme.label)
                    Spacer()
                    if mat.unitCost > 0 {
                        Text(String(format: "$%.2f", mat.totalCost))
                            .font(.caption)
                            .foregroundColor(ScaffoldTheme.secondaryLabel)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(mat.name)\(mat.unitCost > 0 ? ", $\(String(format: "%.2f", mat.totalCost))" : "")")
            }

            if unpurchasedMaterials.count > 4 {
                Text("+ \(unpurchasedMaterials.count - 4) more")
                    .font(.caption)
                    .foregroundColor(ScaffoldTheme.secondaryLabel)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ScaffoldTheme.secondaryBackground)
        )
    }
}

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ScaffoldTheme.label)
                    Text(project.room?.name ?? "")
                        .font(.caption)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
                Spacer()
                Label(project.status.rawValue, systemImage: project.status.icon)
                    .font(.caption)
                    .foregroundColor(ScaffoldTheme.statusColor(project.status))
            }

            if !project.tasks.isEmpty {
                ProgressView(value: project.taskCompletionFraction)
                    .tint(ScaffoldTheme.statusColor(project.status))
                    .accessibilityLabel("Task progress: \(Int(project.taskCompletionFraction * 100))%")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ScaffoldTheme.secondaryBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(project.name), \(project.status.rawValue)")
    }
}
