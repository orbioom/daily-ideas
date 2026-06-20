import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScriptProject.updatedAt, order: .reverse) private var projects: [ScriptProject]
    @Query private var allSettings: [ScriptSettings]
    @State private var showNewProject = false
    @State private var searchText = ""
    @State private var sortOrder = "updated"

    private var settings: ScriptSettings {
        allSettings.first ?? ScriptSettings()
    }

    private var filtered: [ScriptProject] {
        guard !searchText.isEmpty else { return projects }
        return projects.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText) ||
            $0.genre.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty && searchText.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Scripts Yet",
                        subtitle: "Tap the pen icon to write your first screenplay.",
                        action: { showNewProject = true },
                        actionLabel: "New Script"
                    )
                } else if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "No Results", subtitle: "Try a different search.")
                } else {
                    List {
                        ForEach(filtered) { project in
                            NavigationLink(destination: EditorView(project: project, settings: settings)) {
                                ProjectRow(project: project)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    project.isFavorite.toggle()
                                } label: {
                                    Label(project.isFavorite ? "Unfave" : "Favorite",
                                          systemImage: project.isFavorite ? "heart.slash" : "heart.fill")
                                }
                                .tint(.pink)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    modelContext.delete(project)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    duplicate(project)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button { duplicate(project) } label: { Label("Duplicate", systemImage: "doc.on.doc") }
                                Button { exportPDF(project) } label: { Label("Export PDF", systemImage: "square.and.arrow.up") }
                                Button(role: .destructive) { modelContext.delete(project) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Scripts")
            .searchable(text: $searchText, prompt: "Search scripts…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewProject = true } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Script")
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectSheet(defaultAuthor: settings.authorName)
            }
        }
    }

    private func duplicate(_ project: ScriptProject) {
        let copy = ScriptProject(
            title: project.title + " (Copy)",
            author: project.author,
            genre: project.genre,
            logline: project.logline,
            draftNumber: project.draftNumber
        )
        copy.content = project.content
        copy.storyNotes = project.storyNotes
        modelContext.insert(copy)
    }

    private func exportPDF(_ project: ScriptProject) {
        let data = ScriptPDFExporter.export(project: project)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(project.title).pdf")
        try? data.write(to: url)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

struct ProjectRow: View {
    let project: ScriptProject
    private var pageCount: Int {
        FountainParser.estimatePageCount(elements: FountainParser.parse(text: project.content))
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(ScriptTheme.colorTag(project.colorTag))
                .frame(width: 6)
                .frame(height: 52)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.title)
                        .font(.headline)
                    if project.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                    Spacer()
                    PageCountBadge(count: pageCount)
                }
                HStack {
                    Text(project.genre)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !project.author.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(project.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(project.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
