import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \Article.dateAdded, order: .reverse) private var articles: [Article]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var showArchived = false

    private var active: [Article] { articles.filter { !$0.isArchived } }
    private var archived: [Article] { articles.filter(\.isArchived) }

    var body: some View {
        List {
            if active.isEmpty && !showArchived {
                emptyState
            } else {
                if !active.isEmpty {
                    Section("Reading List") {
                        ForEach(active) { article in
                            NavigationLink(destination: ReaderView(article: article)) {
                                ArticleRowView(article: article)
                            }
                            .swipeActions(edge: .leading) {
                                Button { article.isArchived = true } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(article)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if !archived.isEmpty {
                    Section {
                        ForEach(archived) { article in
                            NavigationLink(destination: ReaderView(article: article)) {
                                ArticleRowView(article: article)
                            }
                            .swipeActions(edge: .leading) {
                                Button { article.isArchived = false } label: {
                                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                                }
                                .tint(.green)
                            }
                        }
                    } header: {
                        Button(showArchived ? "Hide Archived" : "Show Archived (\(archived.count))") {
                            showArchived.toggle()
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add new article")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddArticleView()
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing to Read",
            systemImage: "books.vertical",
            description: Text("Tap + to paste any text and start reading at speed.")
        )
        .listRowBackground(Color.clear)
    }
}

private struct ArticleRowView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(2)
            HStack(spacing: 8) {
                Text("\(article.wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                Text(readingTimeStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if article.isCompleted {
                    Text("·")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    Text("Done")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if article.progressFraction > 0 {
                    Text("·")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    Text("\(Int(article.progressFraction * 100))%")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            if article.progressFraction > 0 && !article.isCompleted {
                ProgressView(value: article.progressFraction)
                    .tint(SkimTheme.accent)
                    .accessibilityLabel("Reading progress: \(Int(article.progressFraction * 100))%")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var readingTimeStr: String {
        let wpm = 250
        let minutes = max(1, article.wordCount / wpm)
        return "\(minutes) min read"
    }
}
