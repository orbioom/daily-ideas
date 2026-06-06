import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.updatedAt, order: .reverse) private var projects: [Project]
    @AppStorage("lengthUnit") private var unitRaw = LengthUnit.mm.rawValue
    @AppStorage("defaultKerfMm") private var defaultKerfMm = 3.0

    @State private var newProject: Project?
    private var unit: LengthUnit { LengthUnit(rawValue: unitRaw) ?? .mm }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if projects.isEmpty {
                        EmptyStateView(icon: "square.stack.3d.up", title: "No projects yet",
                                       message: "Create a project, list its parts and stock, and Kerf will plan the cuts.")
                    } else { list }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { create() } label: { Image(systemName: "plus") }.accessibilityLabel("New project")
                }
            }
            .navigationDestination(for: Project.self) { ProjectDetailView(project: $0) }
            .sheet(item: $newProject) { ProjectEditView(project: $0, isNew: true) }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(projects) { project in
                    NavigationLink(value: project) { row(project) }.buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) { delete(project) } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func row(_ p: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(p.name.isEmpty ? "Untitled project" : p.name).font(.headline).foregroundStyle(Brand.text)
            HStack(spacing: 8) {
                Pill(text: "\(p.totalPieces) pieces")
                Pill(text: "\(p.stock.count) stock")
                Pill(text: "kerf \(unit.string(p.kerfMm))")
                Spacer()
            }
        }
        .glassCard()
    }

    private func create() {
        let p = Project(name: "", kerfMm: defaultKerfMm)
        p.stock = [StockBoard(label: "Board", lengthMm: unit.toMM(unit == .mm ? 2400 : 96), quantity: 0)]
        context.insert(p); newProject = p; Haptics.tap()
    }
    private func delete(_ p: Project) { context.delete(p); try? context.save(); Haptics.warning() }
}
