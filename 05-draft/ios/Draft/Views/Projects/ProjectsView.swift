import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Query(sort: \DraftProject.updatedAt, order: .reverse) private var projects: [DraftProject]
    @Environment(\.modelContext) private var modelContext
    @State private var showNewProject = false
    @State private var searchText = ""

    private var filtered: [DraftProject] {
        if searchText.isEmpty { return projects }
        return projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.genre.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()

                if projects.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCardView(project: project)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) { modelContext.delete(project) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .searchable(text: $searchText, prompt: "Search projects…")
                }
            }
            .navigationTitle("Draft")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewProject = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15))
                    }
                }
            }
            .sheet(isPresented: $showNewProject) {
                NewProjectSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(red: 0.85, green: 0.58, blue: 0.15).opacity(0.6))
            Text("Your Stories Await")
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            Text("Tap + to start your first project.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            Button(action: { showNewProject = true }) {
                Label("New Project", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.85, green: 0.58, blue: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(40)
    }
}

struct ProjectCardView: View {
    let project: DraftProject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(project.genre)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                statusBadge(project.status)
            }

            if !project.logline.isEmpty {
                Text(project.logline)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }

            VStack(spacing: 6) {
                ProgressView(value: project.progressFraction)
                    .tint(Color(red: 0.85, green: 0.58, blue: 0.15))
                HStack {
                    Text("\(project.currentWordCount.formatted()) words")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                    Text("Goal: \(project.targetWordCount.formatted())")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            HStack {
                Label("\(project.characters.count) characters", systemImage: "person.fill")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Label("\(project.chapters.count) chapters", systemImage: "list.number")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(project.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.85, green: 0.58, blue: 0.15).opacity(0.2), lineWidth: 1)
        )
    }

    private func statusBadge(_ status: ProjectStatus) -> some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ s: ProjectStatus) -> Color {
        switch s {
        case .idea: return .gray.opacity(0.6)
        case .outlining: return .yellow.opacity(0.6)
        case .drafting: return .blue.opacity(0.6)
        case .revising: return .orange.opacity(0.6)
        case .complete: return .green.opacity(0.6)
        case .shelved: return .red.opacity(0.5)
        }
    }
}

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var genre = ProjectGenre.fantasy.rawValue
    @State private var targetWordCount = 80000

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.02).ignoresSafeArea()

                Form {
                    Section("Project") {
                        TextField("Title", text: $title)
                            .font(.system(size: 16, design: .rounded))
                        Picker("Genre", selection: $genre) {
                            ForEach(ProjectGenre.allCases, id: \.rawValue) { g in
                                Text(g.rawValue).tag(g.rawValue)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section("Word Count Goal") {
                        Stepper("\(targetWordCount.formatted()) words", value: $targetWordCount, in: 1000...500000, step: 5000)
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let p = DraftProject(title: title.isEmpty ? "Untitled" : title, genre: genre)
                        p.targetWordCount = targetWordCount
                        modelContext.insert(p)
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
