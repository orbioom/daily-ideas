import SwiftUI
import SwiftData

struct StoriesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FableStory.createdAt, order: .reverse) private var stories: [FableStory]
    @Query private var settingsQ: [FableSettings]
    @State private var showAdd = false
    @State private var showTemplates = false
    @State private var genreFilter: StoryGenre?
    @State private var showFavoritesOnly = false
    @State private var searchText = ""

    private var childName: String { settingsQ.first?.childName ?? "" }

    var filtered: [FableStory] {
        var list = stories
        if let g = genreFilter { list = list.filter { $0.genre == g } }
        if showFavoritesOnly { list = list.filter { $0.isFavorite } }
        if !searchText.isEmpty {
            list = list.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            Group {
                if stories.isEmpty {
                    emptyState
                } else {
                    List {
                        filterRow
                        ForEach(filtered) { story in
                            NavigationLink(value: story) {
                                StoryRowView(story: story)
                            }
                        }
                        .onDelete { idx in
                            let list = filtered
                            for i in idx { context.delete(list[i]) }
                            try? context.save()
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search stories")
                }
            }
            .navigationTitle(childName.isEmpty ? "Stories" : "\(childName)'s Stories")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: FableStory.self) { StoryDetailView(story: $0) }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFavoritesOnly.toggle() }) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundColor(showFavoritesOnly ? .yellow : .primary)
                    }
                    .accessibilityLabel(showFavoritesOnly ? "Show all stories" : "Show favorites only")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showAdd = true }) {
                            Label("Create from Scratch", systemImage: "pencil")
                        }
                        Button(action: { showTemplates = true }) {
                            Label("Use a Template", systemImage: "doc.text")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add story")
                }
            }
            .sheet(isPresented: $showAdd) { AddEditStoryView(story: nil) }
            .sheet(isPresented: $showTemplates) { TemplatesGalleryView() }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                genreChip("All", nil)
                ForEach(StoryGenre.allCases, id: \.self) { g in
                    genreChip(g.rawValue, g)
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
    }

    private func genreChip(_ label: String, _ genre: StoryGenre?) -> some View {
        let selected = genreFilter == genre
        return Button(action: { genreFilter = selected ? nil : genre }) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(selected ? FableTheme.accent : FableTheme.secondary))
                .foregroundColor(selected ? .white : FableTheme.secondaryLabel)
        }
        .accessibilityLabel(label + (selected ? ", selected" : ""))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("📖").font(.system(size: 64)).accessibilityHidden(true)
            Text("No Stories Yet").font(.title2.bold())
            Text("Create your first bedtime story!").foregroundColor(FableTheme.secondaryLabel)
            HStack(spacing: 12) {
                Button("From Template") { showTemplates = true }.buttonStyle(.bordered)
                    .accessibilityLabel("Create story from template")
                Button("From Scratch") { showAdd = true }.buttonStyle(.borderedProminent)
                    .accessibilityLabel("Create story from scratch")
            }
        }
        .padding()
    }
}

struct StoryRowView: View {
    let story: FableStory
    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(story.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FableTheme.label)
                Spacer()
                if story.isFavorite {
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                }
            }
            HStack(spacing: 8) {
                Label(story.genre.rawValue, systemImage: story.genre.icon)
                    .font(.caption)
                    .foregroundColor(FableTheme.genreColor(story.genre))
                Text("·").foregroundColor(FableTheme.secondaryLabel)
                Text(story.ageGroup.rawValue)
                    .font(.caption)
                    .foregroundColor(FableTheme.secondaryLabel)
                if story.readCount > 0 {
                    Text("·").foregroundColor(FableTheme.secondaryLabel)
                    Text("Read \(story.readCount)x")
                        .font(.caption)
                        .foregroundColor(FableTheme.secondaryLabel)
                }
            }
            if !story.characters.isEmpty {
                HStack(spacing: 4) {
                    ForEach(story.characters.prefix(4)) { c in
                        Text(c.emoji).font(.caption)
                    }
                    if story.characters.count > 4 {
                        Text("+\(story.characters.count - 4)").font(.caption2).foregroundColor(FableTheme.secondaryLabel)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.title), \(story.genre.rawValue), \(story.ageGroup.rawValue)")
    }
}
