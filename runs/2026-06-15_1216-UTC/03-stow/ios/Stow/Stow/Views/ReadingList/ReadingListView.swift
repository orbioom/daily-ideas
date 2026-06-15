import SwiftUI
import SwiftData

struct ReadingListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    // Unread = not archived. Sorted in-memory after fetch for flexible orders.
    @Query(filter: #Predicate<Article> { !$0.isArchived }, sort: \Article.savedAt, order: .reverse)
    private var articles: [Article]

    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var searchText = ""
    @State private var sort: ArticleSort = .recent
    @State private var selectedTagID: UUID?
    @State private var showAdd = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Group {
                    if articles.isEmpty {
                        EmptyStateView(
                            icon: "books.vertical",
                            title: "Your reading nook is empty",
                            message: "Save your first article and Stow will keep a clean, offline copy for you.",
                            actionTitle: "Add an article",
                            action: { startAdd() }
                        )
                    } else if filtered.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "Nothing matches",
                            message: "Try a different search or clear your filters."
                        )
                    } else {
                        listView
                    }
                }
            }
            .navigationTitle("Read")
            .searchable(text: $searchText, prompt: "Search your articles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(ArticleSort.allCases) { s in
                                Text(s.title).tag(s)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort articles")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startAdd() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add article")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddArticleView(currentSavedCount: savedCount, wordsPerMinute: settings.wordsPerMinute)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .articleLimit)
            }
        }
    }

    // MARK: List

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !allTags.isEmpty {
                    tagFilterRow
                }
                ForEach(filtered) { article in
                    SwipeRow(
                        favorite: { toggleFavorite(article) },
                        isFavorite: article.isFavorite,
                        archive: { archive(article) },
                        delete: { delete(article) }
                    ) {
                        NavigationLink {
                            ReaderView(article: article)
                        } label: {
                            ArticleCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                    .contextMenu {
                        Button { toggleFavorite(article) } label: {
                            Label(article.isFavorite ? "Unfavorite" : "Favorite",
                                  systemImage: article.isFavorite ? "heart.slash" : "heart")
                        }
                        Button { archive(article) } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        Button(role: .destructive) { delete(article) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var tagFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ChipView(label: "All", isSelected: selectedTagID == nil) {
                    settings.haptic { Haptics.selection() }
                    selectedTagID = nil
                }
                ForEach(allTags) { tag in
                    ChipView(
                        label: tag.name,
                        tint: Color(hex: TagPalette.color(for: tag.colorHex)),
                        isSelected: selectedTagID == tag.id
                    ) {
                        settings.haptic { Haptics.selection() }
                        selectedTagID = (selectedTagID == tag.id) ? nil : tag.id
                    }
                }
            }
            .padding(.bottom, 2)
        }
    }

    // MARK: Derived data

    private var savedCount: Int { articles.count }

    private var filtered: [Article] {
        var items = articles

        if let tagID = selectedTagID {
            items = items.filter { $0.tags.contains { $0.id == tagID } }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            items = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.siteName.lowercased().contains(query) ||
                $0.excerpt.lowercased().contains(query)
            }
        }

        switch sort {
        case .recent:
            items.sort { $0.savedAt > $1.savedAt }
        case .longest:
            items.sort { $0.wordCount > $1.wordCount }
        case .shortest:
            items.sort { $0.wordCount < $1.wordCount }
        }
        return items
    }

    // MARK: Actions

    private func startAdd() {
        if Pro.canSaveMore(currentCount: savedCount, isPro: isPro) {
            showAdd = true
        } else {
            showPaywall = true
        }
    }

    private func toggleFavorite(_ article: Article) {
        settings.haptic { Haptics.tap() }
        article.isFavorite.toggle()
        try? context.save()
    }

    private func archive(_ article: Article) {
        settings.haptic { Haptics.tap() }
        withAnimation {
            article.isArchived = true
        }
        try? context.save()
    }

    private func delete(_ article: Article) {
        settings.haptic { Haptics.warning() }
        withAnimation {
            context.delete(article)
        }
        try? context.save()
    }
}
